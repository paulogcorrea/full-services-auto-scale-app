// User Models
export interface User {
  id: string;
  username: string;
  email: string;
  first_name: string;
  last_name: string;
  role: UserRole;
  is_active: boolean;
  tenant_id?: string;
  created_at: string;
  updated_at: string;
}

export type UserRole = 'admin' | 'user' | 'tenant_admin';

// Auth Models
export interface LoginRequest {
  username: string;
  password: string;
}

export interface RegisterRequest {
  username: string;
  email: string;
  password: string;
  first_name: string;
  last_name: string;
}

export interface LoginResponse {
  token: string;
  refresh_token: string;
  user: User;
  expires_at: string;
}

// Service Models
export interface Service {
  id: string;
  name: string;
  type: ServiceType;
  status: ServiceStatus;
  description: string;
  config: ServiceConfig;
  tenant_id?: string;
  created_by: string;
  created_at: string;
  updated_at: string;
  deployments?: ServiceDeployment[];
}

export type ServiceType = 'database' | 'web_server' | 'message_queue' | 'monitoring' | 'devops' | 'custom';
export type ServiceStatus = 'running' | 'stopped' | 'error' | 'pending';

export interface ServiceConfig {
  image: string;
  ports: number[];
  environment: Record<string, string>;
  volumes?: string[];
  resources: ResourceConfig;
  health_check?: HealthCheckConfig;
  nomad_job_file: string;
  custom_variables?: Record<string, string>;
}

export interface ResourceConfig {
  cpu: number; // MHz
  memory: number; // MB
  disk: number; // MB
}

export interface HealthCheckConfig {
  enabled: boolean;
  path?: string;
  interval?: string;
  timeout?: string;
  retries?: number;
}

export interface ServiceDeployment {
  id: string;
  service_id: string;
  status: DeploymentStatus;
  nomad_job_id: string;
  started_at?: string;
  completed_at?: string;
  error_msg?: string;
  deployed_by: string;
  created_at: string;
  updated_at: string;
}

export type DeploymentStatus = 'pending' | 'running' | 'completed' | 'failed';

export interface CreateServiceRequest {
  name: string;
  type: ServiceType;
  description: string;
  config: ServiceConfig;
}

// Service Template Models
export interface ServiceTemplate {
  id: string;
  name: string;
  type: ServiceType;
  description: string;
  icon?: string;
  category: string;
  tags: string[];
  config: ServiceConfig;
  is_public: boolean;
  created_at: string;
  updated_at: string;
}

// Dashboard Models
export interface DashboardStats {
  total_services: number;
  running_services: number;
  stopped_services: number;
  error_services: number;
  recent_deployments: ServiceDeployment[];
}

// API Response Models
export interface ApiResponse<T> {
  data?: T;
  message?: string;
  error?: string;
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
}

export interface ServiceListResponse {
  services: Service[];
  total: number;
}

export interface ServiceLogsResponse {
  logs: string[];
}

export interface ServiceMetricsResponse {
  metrics: {
    cpu_usage: number;
    memory_usage: number;
    allocation_id: string;
    allocation_status: string;
    node_id: string;
  };
}

// Form Models
export interface ServiceFormData {
  name: string;
  type: ServiceType;
  description: string;
  image: string;
  ports: string; // comma-separated
  environment: EnvironmentVariable[];
  resources: ResourceConfig;
  nomad_job_file: string;
  custom_variables: EnvironmentVariable[];
}

export interface EnvironmentVariable {
  key: string;
  value: string;
}

// Notification Models
export interface Notification {
  id: string;
  type: 'success' | 'error' | 'warning' | 'info';
  title: string;
  message: string;
  timestamp: Date;
  read: boolean;
}

// Error Models
export interface ApiError {
  error: string;
  status?: number;
  timestamp?: string;
}

// Chart Models
export interface ChartData {
  labels: string[];
  datasets: {
    label: string;
    data: number[];
    backgroundColor?: string[];
    borderColor?: string[];
  }[];
}

// Filter Models
export interface ServiceFilter {
  type?: ServiceType;
  status?: ServiceStatus;
  search?: string;
}

// Table Models
export interface TableColumn {
  key: string;
  label: string;
  sortable?: boolean;
  type?: 'text' | 'date' | 'status' | 'actions';
}

export interface SortOptions {
  column: string;
  direction: 'asc' | 'desc';
}
