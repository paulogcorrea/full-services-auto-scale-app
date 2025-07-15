#!/bin/bash

# Nomad Autoscaler Management Script
# This script manages the Nomad Autoscaler deployment and configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_DIR="$(dirname "$(dirname "$(pwd)")")"
NOMAD_ENVIRONMENT_DIR="$BASE_DIR/nomad-environment"
NOMAD_JOBS_DIR="$NOMAD_ENVIRONMENT_DIR/jobs"
NOMAD_ENDPOINT="http://localhost:4646"
AUTOSCALER_JOB="$NOMAD_JOBS_DIR/nomad-autoscaler.nomad"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

# Function to check if Nomad is running
check_nomad() {
    if ! curl -s "$NOMAD_ENDPOINT/v1/status/leader" > /dev/null 2>&1; then
        print_error "Nomad server is not running at $NOMAD_ENDPOINT"
        print_warning "Please start Nomad server before running this script"
        exit 1
    fi
    print_status "Nomad server is running"
}

# Function to check if Prometheus is running
check_prometheus() {
    if ! curl -s "http://localhost:9090/api/v1/query?query=up" > /dev/null 2>&1; then
        print_warning "Prometheus is not running at localhost:9090"
        print_warning "Autoscaler will not be able to fetch metrics"
        print_warning "Please deploy Prometheus before enabling autoscaling"
    else
        print_status "Prometheus is running and accessible"
    fi
}

# Function to deploy autoscaler
deploy_autoscaler() {
    print_header "Deploying Nomad Autoscaler..."
    
    check_nomad
    check_prometheus
    
    if [ ! -f "$AUTOSCALER_JOB" ]; then
        print_error "Autoscaler job file not found: $AUTOSCALER_JOB"
        exit 1
    fi
    
    print_status "Deploying autoscaler job..."
    if nomad job run "$AUTOSCALER_JOB"; then
        print_status "Autoscaler deployed successfully"
        print_status "Autoscaler API: http://localhost:8080"
        print_status "Health check: http://localhost:8080/v1/health"
    else
        print_error "Failed to deploy autoscaler"
        exit 1
    fi
}

# Function to stop autoscaler
stop_autoscaler() {
    print_header "Stopping Nomad Autoscaler..."
    
    check_nomad
    
    if nomad job stop nomad-autoscaler; then
        print_status "Autoscaler stopped successfully"
    else
        print_error "Failed to stop autoscaler"
        exit 1
    fi
}

# Function to check autoscaler status
check_status() {
    print_header "Checking Autoscaler Status..."
    
    check_nomad
    
    print_status "Autoscaler job status:"
    nomad job status nomad-autoscaler || print_warning "Autoscaler job not found"
    
    print_status "Autoscaler allocations:"
    nomad alloc status -verbose $(nomad job allocs nomad-autoscaler | grep -E "running|pending" | head -1 | awk '{print $1}') || print_warning "No running allocations found"
    
    print_status "Checking autoscaler API health:"
    if curl -s http://localhost:8080/v1/health > /dev/null 2>&1; then
        print_status "Autoscaler API is healthy"
        curl -s http://localhost:8080/v1/health | python3 -m json.tool
    else
        print_warning "Autoscaler API is not responding"
    fi
}

# Function to view autoscaler logs
view_logs() {
    print_header "Viewing Autoscaler Logs..."
    
    check_nomad
    
    ALLOC_ID=$(nomad job allocs nomad-autoscaler | grep running | head -1 | awk '{print $1}')
    
    if [ -z "$ALLOC_ID" ]; then
        print_error "No running autoscaler allocation found"
        exit 1
    fi
    
    print_status "Showing logs for allocation: $ALLOC_ID"
    nomad alloc logs -follow "$ALLOC_ID" autoscaler
}

# Function to list scaling policies
list_policies() {
    print_header "Listing Autoscaling Policies..."
    
    check_nomad
    
    if curl -s http://localhost:8080/v1/policies > /dev/null 2>&1; then
        print_status "Active scaling policies:"
        curl -s http://localhost:8080/v1/policies | python3 -m json.tool
    else
        print_warning "Cannot access autoscaler API at http://localhost:8080"
    fi
}

# Function to show scaling history
show_history() {
    print_header "Showing Scaling History..."
    
    check_nomad
    
    if curl -s http://localhost:8080/v1/scaling/history > /dev/null 2>&1; then
        print_status "Recent scaling events:"
        curl -s http://localhost:8080/v1/scaling/history | python3 -m json.tool
    else
        print_warning "Cannot access autoscaler API at http://localhost:8080"
    fi
}

# Function to enable/disable scaling for a job
toggle_scaling() {
    local job_name="$1"
    local action="$2"
    
    if [ -z "$job_name" ] || [ -z "$action" ]; then
        print_error "Usage: toggle_scaling <job_name> <enable|disable>"
        exit 1
    fi
    
    print_header "Toggling scaling for job: $job_name"
    
    check_nomad
    
    case "$action" in
        "enable")
            print_status "Enabling scaling for $job_name..."
            # This would typically involve updating the job configuration
            print_warning "Manual job update required to enable scaling"
            ;;
        "disable")
            print_status "Disabling scaling for $job_name..."
            # This would typically involve updating the job configuration
            print_warning "Manual job update required to disable scaling"
            ;;
        *)
            print_error "Invalid action: $action. Use 'enable' or 'disable'"
            exit 1
            ;;
    esac
}

# Function to create a custom scaling policy
create_policy() {
    local policy_name="$1"
    
    if [ -z "$policy_name" ]; then
        print_error "Usage: create_policy <policy_name>"
        exit 1
    fi
    
    print_header "Creating Custom Scaling Policy: $policy_name"
    
    # Create a template policy file
    cat > "/tmp/${policy_name}.hcl" << 'EOF'
scaling "custom_scaling_policy" {
  enabled = true
  min     = 1
  max     = 5

  policy {
    cooldown            = "2m"
    evaluation_interval = "30s"

    check "cpu_usage" {
      source = "prometheus"
      query  = "avg(nomad_client_allocs_cpu_total_percent{job=\"your-job-name\"})"

      strategy "target-value" {
        target = 75
      }
    }
  }

  target {
    Namespace = "default"
    Job       = "your-job-name"
    Group     = "your-group-name"
  }
}
EOF
    
    print_status "Template policy created at: /tmp/${policy_name}.hcl"
    print_status "Please edit the file and customize it for your needs"
    print_status "Then add it to your job configuration or autoscaler policy directory"
}

# Function to show scaling recommendations
show_recommendations() {
    print_header "Scaling Recommendations..."
    
    print_status "Based on your services, here are scaling recommendations:"
    echo
    
    print_status "1. Web Services (nodejs, php, java):"
    echo "   - Scale based on CPU usage (target: 70-80%)"
    echo "   - Scale based on request rate (target: 100 req/sec)"
    echo "   - Min: 1, Max: 5-10 instances"
    echo
    
    print_status "2. Data Services (redis, postgresql, mongodb):"
    echo "   - Scale based on memory usage (target: 80%)"
    echo "   - Scale based on connection count"
    echo "   - Min: 1, Max: 3 instances (careful with data consistency)"
    echo
    
    print_status "3. Monitoring Services (prometheus, grafana):"
    echo "   - Scale based on query load"
    echo "   - Scale based on ingestion rate"
    echo "   - Min: 1, Max: 3 instances"
    echo
    
    print_status "4. CI/CD Services (jenkins, sonarqube):"
    echo "   - Scale based on build queue size"
    echo "   - Scale based on CPU usage during builds"
    echo "   - Min: 1, Max: 5 instances"
    echo
}

# Function to show help
show_help() {
    print_header "Nomad Autoscaler Management Script"
    echo
    echo "Usage: $0 <command> [options]"
    echo
    echo "Commands:"
    echo "  deploy              Deploy the Nomad Autoscaler"
    echo "  stop                Stop the Nomad Autoscaler"
    echo "  status              Check autoscaler status"
    echo "  logs                View autoscaler logs"
    echo "  policies            List active scaling policies"
    echo "  history             Show scaling history"
    echo "  toggle <job> <action>  Enable/disable scaling for a job"
    echo "  create-policy <name>   Create a custom scaling policy template"
    echo "  recommendations     Show scaling recommendations"
    echo "  help                Show this help message"
    echo
    echo "Examples:"
    echo "  $0 deploy"
    echo "  $0 status"
    echo "  $0 logs"
    echo "  $0 toggle nodejs-server enable"
    echo "  $0 create-policy my-custom-policy"
    echo
}

# Main script logic
case "${1:-help}" in
    "deploy")
        deploy_autoscaler
        ;;
    "stop")
        stop_autoscaler
        ;;
    "status")
        check_status
        ;;
    "logs")
        view_logs
        ;;
    "policies")
        list_policies
        ;;
    "history")
        show_history
        ;;
    "toggle")
        toggle_scaling "$2" "$3"
        ;;
    "create-policy")
        create_policy "$2"
        ;;
    "recommendations")
        show_recommendations
        ;;
    "help"|*)
        show_help
        ;;
esac
