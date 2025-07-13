package services

import (
	"fmt"
	"io/ioutil"
	"path/filepath"
	"strings"
	"time"

	"nomad-services-api/internal/config"
	"nomad-services-api/internal/models"

	"github.com/hashicorp/nomad/api"
	"github.com/sirupsen/logrus"
)

type NomadService struct {
	client *api.Client
	config *config.Config
}

func NewNomadService(cfg *config.Config) *NomadService {
	nomadConfig := api.DefaultConfig()
	nomadConfig.Address = cfg.Nomad.Address
	nomadConfig.Namespace = cfg.Nomad.Namespace
	
	if cfg.Nomad.Token != "" {
		nomadConfig.SecretID = cfg.Nomad.Token
	}

	client, err := api.NewClient(nomadConfig)
	if err != nil {
		logrus.WithError(err).Fatal("Failed to create Nomad client")
	}

	return &NomadService{
		client: client,
		config: cfg,
	}
}

func (ns *NomadService) GetJobStatus(jobID string) (*api.Job, error) {
	jobs := ns.client.Jobs()
	job, _, err := jobs.Info(jobID, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to get job info: %w", err)
	}
	return job, nil
}

func (ns *NomadService) ListJobs() ([]*api.JobListStub, error) {
	jobs := ns.client.Jobs()
	jobList, _, err := jobs.List(nil)
	if err != nil {
		return nil, fmt.Errorf("failed to list jobs: %w", err)
	}
	return jobList, nil
}

func (ns *NomadService) DeployService(service *models.Service, tenantID string) (*models.ServiceDeployment, error) {
	logrus.WithFields(logrus.Fields{
		"service_id":   service.ID,
		"service_name": service.Name,
		"tenant_id":    tenantID,
	}).Info("Deploying service")

	// Generate unique job ID
	jobID := fmt.Sprintf("%s-%s-%d", tenantID, service.Name, time.Now().Unix())

	// Read job file
	jobContent, err := ns.readJobFile(service.Config.NomadJobFile)
	if err != nil {
		return nil, fmt.Errorf("failed to read job file: %w", err)
	}

	// Replace variables in job content
	jobContent = ns.replaceVariables(jobContent, service, jobID)

	// Parse job
	job, err := ns.parseJob(jobContent)
	if err != nil {
		return nil, fmt.Errorf("failed to parse job: %w", err)
	}

	// Set job ID
	job.ID = &jobID

	// Submit job
	jobs := ns.client.Jobs()
	_, _, err = jobs.Register(job, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to register job: %w", err)
	}

	// Create deployment record
	deployment := &models.ServiceDeployment{
		ServiceID:  service.ID,
		Status:     models.DeploymentStatusPending,
		NomadJobID: jobID,
		DeployedBy: service.CreatedBy,
	}

	return deployment, nil
}

func (ns *NomadService) StopService(jobID string) error {
	jobs := ns.client.Jobs()
	_, _, err := jobs.Deregister(jobID, true, nil)
	if err != nil {
		return fmt.Errorf("failed to deregister job: %w", err)
	}
	return nil
}

func (ns *NomadService) RestartService(jobID string) error {
	// Get current job
	job, err := ns.GetJobStatus(jobID)
	if err != nil {
		return fmt.Errorf("failed to get job status: %w", err)
	}

	// Force new deployment
	jobs := ns.client.Jobs()
	_, _, err = jobs.Register(job, &api.RegisterOptions{
		EnforceIndex: true,
	})
	if err != nil {
		return fmt.Errorf("failed to restart job: %w", err)
	}

	return nil
}

func (ns *NomadService) GetServiceLogs(jobID string, taskName string) ([]string, error) {
	// Get allocations for the job
	jobs := ns.client.Jobs()
	allocs, _, err := jobs.Allocations(jobID, false, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to get allocations: %w", err)
	}

	if len(allocs) == 0 {
		return []string{}, nil
	}

	// Get logs from the most recent allocation
	latestAlloc := allocs[0]
	allocsClient := ns.client.Allocations()
	
	logs, err := allocsClient.Logs(latestAlloc.ID, true, taskName, "stdout", "start", 0, nil, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to get logs: %w", err)
	}
	defer logs.Close()

	var logLines []string
	for {
		select {
		case log := <-logs.OutCh:
			if log.Data != nil {
				logLines = append(logLines, string(log.Data))
			}
		case <-logs.ErrCh:
			return logLines, nil
		}
	}
}

func (ns *NomadService) GetServiceMetrics(jobID string) (map[string]interface{}, error) {
	// Get allocations for the job
	jobs := ns.client.Jobs()
	allocs, _, err := jobs.Allocations(jobID, false, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to get allocations: %w", err)
	}

	metrics := make(map[string]interface{})
	
	if len(allocs) == 0 {
		metrics["status"] = "no_allocations"
		return metrics, nil
	}

	// Get stats from the most recent allocation
	latestAlloc := allocs[0]
	allocsClient := ns.client.Allocations()
	
	stats, err := allocsClient.Stats(latestAlloc.ID, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to get allocation stats: %w", err)
	}

	metrics["cpu_usage"] = stats.ResourceUsage.CpuStats.TotalTicks
	metrics["memory_usage"] = stats.ResourceUsage.MemoryStats.RSS
	metrics["allocation_id"] = latestAlloc.ID
	metrics["allocation_status"] = latestAlloc.ClientStatus
	metrics["node_id"] = latestAlloc.NodeID

	return metrics, nil
}

func (ns *NomadService) GetAvailableJobTemplates() ([]models.ServiceTemplate, error) {
	templates := []models.ServiceTemplate{}
	
	// Read job files from the jobs directory
	files, err := ioutil.ReadDir(ns.config.Nomad.JobsPath)
	if err != nil {
		return templates, fmt.Errorf("failed to read jobs directory: %w", err)
	}

	for _, file := range files {
		if !strings.HasSuffix(file.Name(), ".nomad") && !strings.HasSuffix(file.Name(), ".hcl") {
			continue
		}

		template := ns.createTemplateFromFile(file.Name())
		templates = append(templates, template)
	}

	return templates, nil
}

func (ns *NomadService) readJobFile(filename string) (string, error) {
	if filename == "" {
		return "", fmt.Errorf("job file name is empty")
	}

	jobPath := filepath.Join(ns.config.Nomad.JobsPath, filename)
	content, err := ioutil.ReadFile(jobPath)
	if err != nil {
		return "", fmt.Errorf("failed to read job file %s: %w", jobPath, err)
	}

	return string(content), nil
}

func (ns *NomadService) replaceVariables(content string, service *models.Service, jobID string) string {
	// Replace common variables
	content = strings.ReplaceAll(content, "{{JOB_ID}}", jobID)
	content = strings.ReplaceAll(content, "{{SERVICE_NAME}}", service.Name)
	content = strings.ReplaceAll(content, "{{IMAGE}}", service.Config.Image)
	
	// Replace custom variables
	for key, value := range service.Config.CustomVariables {
		placeholder := fmt.Sprintf("{{%s}}", key)
		content = strings.ReplaceAll(content, placeholder, value)
	}

	// Replace environment variables
	for key, value := range service.Config.Environment {
		placeholder := fmt.Sprintf("{{ENV_%s}}", key)
		content = strings.ReplaceAll(content, placeholder, value)
	}

	return content
}

func (ns *NomadService) parseJob(content string) (*api.Job, error) {
	// Parse the job using Nomad's HCL parser
	job, err := api.ParseJob(content)
	if err != nil {
		return nil, fmt.Errorf("failed to parse job: %w", err)
	}

	return job, nil
}

func (ns *NomadService) createTemplateFromFile(filename string) models.ServiceTemplate {
	name := strings.TrimSuffix(filename, filepath.Ext(filename))
	
	// Map common service names to types
	serviceType := ns.getServiceTypeFromName(name)
	
	return models.ServiceTemplate{
		Name:        name,
		Type:        serviceType,
		Description: fmt.Sprintf("Template for %s service", name),
		Config: models.ServiceConfig{
			NomadJobFile: filename,
		},
		IsPublic: true,
	}
}

func (ns *NomadService) getServiceTypeFromName(name string) models.ServiceType {
	name = strings.ToLower(name)
	
	switch {
	case strings.Contains(name, "mysql") || strings.Contains(name, "postgres") || 
		 strings.Contains(name, "mongodb") || strings.Contains(name, "redis"):
		return models.ServiceTypeDatabase
	case strings.Contains(name, "nginx") || strings.Contains(name, "apache") ||
		 strings.Contains(name, "nodejs") || strings.Contains(name, "php"):
		return models.ServiceTypeWebServer
	case strings.Contains(name, "kafka") || strings.Contains(name, "rabbitmq"):
		return models.ServiceTypeMessageQueue
	case strings.Contains(name, "prometheus") || strings.Contains(name, "grafana") ||
		 strings.Contains(name, "loki"):
		return models.ServiceTypeMonitoring
	case strings.Contains(name, "jenkins") || strings.Contains(name, "nexus") ||
		 strings.Contains(name, "sonar"):
		return models.ServiceTypeDevOps
	default:
		return models.ServiceTypeCustom
	}
}
