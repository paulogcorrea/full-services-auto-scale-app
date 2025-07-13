package services

import (
	"fmt"

	"nomad-services-api/internal/config"
	"nomad-services-api/internal/models"

	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
	"gorm.io/gorm"
)

type ServiceManager struct {
	nomadService *NomadService
	config       *config.Config
	db           *gorm.DB
}

func NewServiceManager(nomadService *NomadService, cfg *config.Config) *ServiceManager {
	return &ServiceManager{
		nomadService: nomadService,
		config:       cfg,
	}
}

func (sm *ServiceManager) SetDB(db *gorm.DB) {
	sm.db = db
}

// CreateService creates a new service with the constraint of one instance per service type per tenant
func (sm *ServiceManager) CreateService(req *CreateServiceRequest, userID uuid.UUID, tenantID *uuid.UUID) (*models.Service, error) {
	// Check if service already exists for this tenant
	if err := sm.validateServiceUniqueness(req.Name, req.Type, tenantID); err != nil {
		return nil, err
	}

	// Check tenant limits
	if err := sm.validateTenantLimits(tenantID); err != nil {
		return nil, err
	}

	// Create service
	service := &models.Service{
		Name:        req.Name,
		Type:        req.Type,
		Description: req.Description,
		Config:      req.Config,
		Status:      models.ServiceStatusStopped,
		CreatedBy:   userID,
		TenantID:    tenantID,
	}

	if err := sm.db.Create(service).Error; err != nil {
		return nil, fmt.Errorf("failed to create service: %w", err)
	}

	logrus.WithFields(logrus.Fields{
		"service_id":   service.ID,
		"service_name": service.Name,
		"service_type": service.Type,
		"tenant_id":    tenantID,
		"user_id":      userID,
	}).Info("Service created")

	return service, nil
}

// StartService starts a service (deploys to Nomad)
func (sm *ServiceManager) StartService(serviceID uuid.UUID, userID uuid.UUID) (*models.ServiceDeployment, error) {
	// Get service
	var service models.Service
	if err := sm.db.First(&service, serviceID).Error; err != nil {
		return nil, fmt.Errorf("service not found: %w", err)
	}

	// Check if service is already running
	if service.Status == models.ServiceStatusRunning {
		return nil, fmt.Errorf("service is already running")
	}

	// Check for existing running deployment
	var existingDeployment models.ServiceDeployment
	err := sm.db.Where("service_id = ? AND status IN (?)", serviceID, 
		[]models.DeploymentStatus{models.DeploymentStatusPending, models.DeploymentStatusRunning}).
		First(&existingDeployment).Error
	
	if err == nil {
		return nil, fmt.Errorf("service deployment already in progress")
	}

	// Generate tenant ID for job naming
	tenantID := "default"
	if service.TenantID != nil {
		tenantID = service.TenantID.String()[:8] // Use first 8 chars of UUID
	}

	// Deploy service
	deployment, err := sm.nomadService.DeployService(&service, tenantID)
	if err != nil {
		return nil, fmt.Errorf("failed to deploy service: %w", err)
	}

	// Save deployment
	deployment.DeployedBy = userID
	if err := sm.db.Create(deployment).Error; err != nil {
		return nil, fmt.Errorf("failed to save deployment: %w", err)
	}

	// Update service status
	service.Status = models.ServiceStatusPending
	if err := sm.db.Save(&service).Error; err != nil {
		logrus.WithError(err).Error("Failed to update service status")
	}

	logrus.WithFields(logrus.Fields{
		"service_id":     service.ID,
		"deployment_id":  deployment.ID,
		"nomad_job_id":   deployment.NomadJobID,
		"user_id":        userID,
	}).Info("Service deployment started")

	return deployment, nil
}

// StopService stops a running service
func (sm *ServiceManager) StopService(serviceID uuid.UUID, userID uuid.UUID) error {
	// Get service
	var service models.Service
	if err := sm.db.First(&service, serviceID).Error; err != nil {
		return fmt.Errorf("service not found: %w", err)
	}

	// Check if service is running
	if service.Status != models.ServiceStatusRunning {
		return fmt.Errorf("service is not running")
	}

	// Get active deployment
	var deployment models.ServiceDeployment
	if err := sm.db.Where("service_id = ? AND status IN (?)", serviceID,
		[]models.DeploymentStatus{models.DeploymentStatusRunning, models.DeploymentStatusCompleted}).
		Order("created_at DESC").First(&deployment).Error; err != nil {
		return fmt.Errorf("no active deployment found: %w", err)
	}

	// Stop service in Nomad
	if err := sm.nomadService.StopService(deployment.NomadJobID); err != nil {
		return fmt.Errorf("failed to stop service in Nomad: %w", err)
	}

	// Update service status
	service.Status = models.ServiceStatusStopped
	if err := sm.db.Save(&service).Error; err != nil {
		return fmt.Errorf("failed to update service status: %w", err)
	}

	logrus.WithFields(logrus.Fields{
		"service_id":    service.ID,
		"nomad_job_id":  deployment.NomadJobID,
		"user_id":       userID,
	}).Info("Service stopped")

	return nil
}

// RestartService restarts a running service
func (sm *ServiceManager) RestartService(serviceID uuid.UUID, userID uuid.UUID) error {
	// Get service
	var service models.Service
	if err := sm.db.First(&service, serviceID).Error; err != nil {
		return fmt.Errorf("service not found: %w", err)
	}

	// Check if service is running
	if service.Status != models.ServiceStatusRunning {
		return fmt.Errorf("service is not running")
	}

	// Get active deployment
	var deployment models.ServiceDeployment
	if err := sm.db.Where("service_id = ? AND status IN (?)", serviceID,
		[]models.DeploymentStatus{models.DeploymentStatusRunning, models.DeploymentStatusCompleted}).
		Order("created_at DESC").First(&deployment).Error; err != nil {
		return fmt.Errorf("no active deployment found: %w", err)
	}

	// Restart service in Nomad
	if err := sm.nomadService.RestartService(deployment.NomadJobID); err != nil {
		return fmt.Errorf("failed to restart service in Nomad: %w", err)
	}

	logrus.WithFields(logrus.Fields{
		"service_id":    service.ID,
		"nomad_job_id":  deployment.NomadJobID,
		"user_id":       userID,
	}).Info("Service restarted")

	return nil
}

// GetService retrieves a service by ID
func (sm *ServiceManager) GetService(serviceID uuid.UUID, tenantID *uuid.UUID) (*models.Service, error) {
	var service models.Service
	query := sm.db.Where("id = ?", serviceID)
	
	if tenantID != nil {
		query = query.Where("tenant_id = ?", tenantID)
	}

	if err := query.First(&service).Error; err != nil {
		return nil, fmt.Errorf("service not found: %w", err)
	}

	return &service, nil
}

// ListServices retrieves all services for a tenant
func (sm *ServiceManager) ListServices(tenantID *uuid.UUID) ([]models.Service, error) {
	var services []models.Service
	query := sm.db.Preload("Deployments").Order("created_at DESC")
	
	if tenantID != nil {
		query = query.Where("tenant_id = ?", tenantID)
	}

	if err := query.Find(&services).Error; err != nil {
		return nil, fmt.Errorf("failed to list services: %w", err)
	}

	return services, nil
}

// GetServiceLogs retrieves logs for a service
func (sm *ServiceManager) GetServiceLogs(serviceID uuid.UUID, tenantID *uuid.UUID) ([]string, error) {
	// Get service
	service, err := sm.GetService(serviceID, tenantID)
	if err != nil {
		return nil, err
	}

	// Get active deployment
	var deployment models.ServiceDeployment
	if err := sm.db.Where("service_id = ? AND status IN (?)", serviceID,
		[]models.DeploymentStatus{models.DeploymentStatusRunning, models.DeploymentStatusCompleted}).
		Order("created_at DESC").First(&deployment).Error; err != nil {
		return []string{}, nil // No active deployment
	}

	// Get logs from Nomad
	taskName := service.Name // Default task name
	logs, err := sm.nomadService.GetServiceLogs(deployment.NomadJobID, taskName)
	if err != nil {
		return nil, fmt.Errorf("failed to get service logs: %w", err)
	}

	return logs, nil
}

// GetServiceMetrics retrieves metrics for a service
func (sm *ServiceManager) GetServiceMetrics(serviceID uuid.UUID, tenantID *uuid.UUID) (map[string]interface{}, error) {
	// Get service
	_, err := sm.GetService(serviceID, tenantID)
	if err != nil {
		return nil, err
	}

	// Get active deployment
	var deployment models.ServiceDeployment
	if err := sm.db.Where("service_id = ? AND status IN (?)", serviceID,
		[]models.DeploymentStatus{models.DeploymentStatusRunning, models.DeploymentStatusCompleted}).
		Order("created_at DESC").First(&deployment).Error; err != nil {
		return map[string]interface{}{"status": "no_active_deployment"}, nil
	}

	// Get metrics from Nomad
	metrics, err := sm.nomadService.GetServiceMetrics(deployment.NomadJobID)
	if err != nil {
		return nil, fmt.Errorf("failed to get service metrics: %w", err)
	}

	return metrics, nil
}

// UpdateServiceStatus updates the status of services based on Nomad job status
func (sm *ServiceManager) UpdateServiceStatus() error {
	// Get all services with pending or running status
	var services []models.Service
	if err := sm.db.Where("status IN (?)", 
		[]models.ServiceStatus{models.ServiceStatusPending, models.ServiceStatusRunning}).
		Find(&services).Error; err != nil {
		return fmt.Errorf("failed to get services for status update: %w", err)
	}

	for _, service := range services {
		// Get latest deployment
		var deployment models.ServiceDeployment
		if err := sm.db.Where("service_id = ?", service.ID).
			Order("created_at DESC").First(&deployment).Error; err != nil {
			continue
		}

		// Get job status from Nomad
		job, err := sm.nomadService.GetJobStatus(deployment.NomadJobID)
		if err != nil {
			logrus.WithError(err).Errorf("Failed to get job status for %s", deployment.NomadJobID)
			continue
		}

		// Update service status based on job status
		var newStatus models.ServiceStatus
		switch *job.Status {
		case "running":
			newStatus = models.ServiceStatusRunning
		case "dead":
			newStatus = models.ServiceStatusStopped
		case "pending":
			newStatus = models.ServiceStatusPending
		default:
			newStatus = models.ServiceStatusError
		}

		if service.Status != newStatus {
			service.Status = newStatus
			if err := sm.db.Save(&service).Error; err != nil {
				logrus.WithError(err).Errorf("Failed to update service status for %s", service.ID)
			}
		}
	}

	return nil
}

// validateServiceUniqueness ensures only one instance of each service type per tenant
func (sm *ServiceManager) validateServiceUniqueness(name string, serviceType models.ServiceType, tenantID *uuid.UUID) error {
	var count int64
	query := sm.db.Model(&models.Service{}).Where("name = ? AND type = ?", name, serviceType)
	
	if tenantID != nil {
		query = query.Where("tenant_id = ?", tenantID)
	} else {
		query = query.Where("tenant_id IS NULL")
	}

	if err := query.Count(&count).Error; err != nil {
		return fmt.Errorf("failed to check service uniqueness: %w", err)
	}

	if count > 0 {
		return fmt.Errorf("service '%s' of type '%s' already exists for this tenant", name, serviceType)
	}

	return nil
}

// validateTenantLimits checks if tenant can create more services
func (sm *ServiceManager) validateTenantLimits(tenantID *uuid.UUID) error {
	if tenantID == nil {
		return nil // No limits for system services
	}

	// Get tenant
	var tenant models.Tenant
	if err := sm.db.First(&tenant, tenantID).Error; err != nil {
		return fmt.Errorf("tenant not found: %w", err)
	}

	// Count current services
	var count int64
	if err := sm.db.Model(&models.Service{}).Where("tenant_id = ?", tenantID).Count(&count).Error; err != nil {
		return fmt.Errorf("failed to count tenant services: %w", err)
	}

	if int(count) >= tenant.MaxServices {
		return fmt.Errorf("tenant has reached maximum number of services (%d)", tenant.MaxServices)
	}

	return nil
}

// CreateServiceRequest represents a service creation request
type CreateServiceRequest struct {
	Name        string                `json:"name" binding:"required"`
	Type        models.ServiceType    `json:"type" binding:"required"`
	Description string                `json:"description"`
	Config      models.ServiceConfig  `json:"config" binding:"required"`
}
