package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type User struct {
	ID        uuid.UUID  `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Email     string     `gorm:"uniqueIndex;not null" json:"email"`
	Username  string     `gorm:"uniqueIndex;not null" json:"username"`
	Password  string     `gorm:"not null" json:"-"`
	FirstName string     `json:"first_name"`
	LastName  string     `json:"last_name"`
	Role      UserRole   `gorm:"default:'user'" json:"role"`
	IsActive  bool       `gorm:"default:true" json:"is_active"`
	TenantID  *uuid.UUID `gorm:"type:uuid" json:"tenant_id"`
	Tenant    *Tenant    `gorm:"foreignKey:TenantID" json:"tenant,omitempty"`
	CreatedAt time.Time  `json:"created_at"`
	UpdatedAt time.Time  `json:"updated_at"`
}

type UserRole string

const (
	UserRoleAdmin      UserRole = "admin"
	UserRoleUser       UserRole = "user"
	UserRoleTenantAdmin UserRole = "tenant_admin"
)

type Tenant struct {
	ID           uuid.UUID    `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Name         string       `gorm:"not null" json:"name"`
	Slug         string       `gorm:"uniqueIndex;not null" json:"slug"`
	Description  string       `json:"description"`
	Domain       string       `gorm:"uniqueIndex" json:"domain"`
	IsActive     bool         `gorm:"default:true" json:"is_active"`
	Plan         TenantPlan   `gorm:"default:'free'" json:"plan"`
	MaxServices  int          `gorm:"default:5" json:"max_services"`
	Users        []User       `gorm:"foreignKey:TenantID" json:"users,omitempty"`
	Services     []Service    `gorm:"foreignKey:TenantID" json:"services,omitempty"`
	Subscription *Subscription `gorm:"foreignKey:TenantID" json:"subscription,omitempty"`
	CreatedAt    time.Time    `json:"created_at"`
	UpdatedAt    time.Time    `json:"updated_at"`
}

type TenantPlan string

const (
	TenantPlanFree       TenantPlan = "free"
	TenantPlanStarter    TenantPlan = "starter"
	TenantPlanPro        TenantPlan = "pro"
	TenantPlanEnterprise TenantPlan = "enterprise"
)

type Service struct {
	ID          uuid.UUID           `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Name        string              `gorm:"not null" json:"name"`
	Type        ServiceType         `gorm:"not null" json:"type"`
	Status      ServiceStatus       `gorm:"default:'stopped'" json:"status"`
	Description string              `json:"description"`
	Config      ServiceConfig       `gorm:"type:jsonb" json:"config"`
	TenantID    *uuid.UUID          `gorm:"type:uuid" json:"tenant_id"`
	Tenant      *Tenant             `gorm:"foreignKey:TenantID" json:"tenant,omitempty"`
	CreatedBy   uuid.UUID           `gorm:"type:uuid;not null" json:"created_by"`
	Creator     User                `gorm:"foreignKey:CreatedBy" json:"creator,omitempty"`
	Deployments []ServiceDeployment `gorm:"foreignKey:ServiceID" json:"deployments,omitempty"`
	CreatedAt   time.Time           `json:"created_at"`
	UpdatedAt   time.Time           `json:"updated_at"`
}

type ServiceType string

const (
	ServiceTypeDatabase     ServiceType = "database"
	ServiceTypeWebServer    ServiceType = "web_server"
	ServiceTypeMessageQueue ServiceType = "message_queue"
	ServiceTypeMonitoring   ServiceType = "monitoring"
	ServiceTypeDevOps       ServiceType = "devops"
	ServiceTypeCustom       ServiceType = "custom"
)

type ServiceStatus string

const (
	ServiceStatusRunning ServiceStatus = "running"
	ServiceStatusStopped ServiceStatus = "stopped"
	ServiceStatusError   ServiceStatus = "error"
	ServiceStatusPending ServiceStatus = "pending"
)

type ServiceConfig struct {
	Image           string            `json:"image"`
	Ports           []int             `json:"ports"`
	Environment     map[string]string `json:"environment"`
	Volumes         []string          `json:"volumes"`
	Resources       ResourceConfig    `json:"resources"`
	HealthCheck     HealthCheckConfig `json:"health_check"`
	NomadJobFile    string            `json:"nomad_job_file"`
	CustomVariables map[string]string `json:"custom_variables"`
}

type ResourceConfig struct {
	CPU    int `json:"cpu"`    // MHz
	Memory int `json:"memory"` // MB
	Disk   int `json:"disk"`   // MB
}

type HealthCheckConfig struct {
	Enabled  bool   `json:"enabled"`
	Path     string `json:"path"`
	Interval string `json:"interval"`
	Timeout  string `json:"timeout"`
	Retries  int    `json:"retries"`
}

type ServiceDeployment struct {
	ID          uuid.UUID        `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	ServiceID   uuid.UUID        `gorm:"type:uuid;not null" json:"service_id"`
	Service     Service          `gorm:"foreignKey:ServiceID" json:"service,omitempty"`
	Status      DeploymentStatus `gorm:"default:'pending'" json:"status"`
	NomadJobID  string           `json:"nomad_job_id"`
	StartedAt   *time.Time       `json:"started_at"`
	CompletedAt *time.Time       `json:"completed_at"`
	ErrorMsg    string           `json:"error_msg"`
	DeployedBy  uuid.UUID        `gorm:"type:uuid;not null" json:"deployed_by"`
	Deployer    User             `gorm:"foreignKey:DeployedBy" json:"deployer,omitempty"`
	CreatedAt   time.Time        `json:"created_at"`
	UpdatedAt   time.Time        `json:"updated_at"`
}

type DeploymentStatus string

const (
	DeploymentStatusPending   DeploymentStatus = "pending"
	DeploymentStatusRunning   DeploymentStatus = "running"
	DeploymentStatusCompleted DeploymentStatus = "completed"
	DeploymentStatusFailed    DeploymentStatus = "failed"
)

type ServiceTemplate struct {
	ID          uuid.UUID     `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Name        string        `gorm:"not null" json:"name"`
	Type        ServiceType   `gorm:"not null" json:"type"`
	Description string        `json:"description"`
	Icon        string        `json:"icon"`
	Category    string        `json:"category"`
	Tags        []string      `gorm:"type:text[]" json:"tags"`
	Config      ServiceConfig `gorm:"type:jsonb" json:"config"`
	IsPublic    bool          `gorm:"default:true" json:"is_public"`
	CreatedBy   uuid.UUID     `gorm:"type:uuid;not null" json:"created_by"`
	Creator     User          `gorm:"foreignKey:CreatedBy" json:"creator,omitempty"`
	CreatedAt   time.Time     `json:"created_at"`
	UpdatedAt   time.Time     `json:"updated_at"`
}

type AuditLog struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	UserID    uuid.UUID `gorm:"type:uuid;not null" json:"user_id"`
	User      User      `gorm:"foreignKey:UserID" json:"user,omitempty"`
	TenantID  *uuid.UUID `gorm:"type:uuid" json:"tenant_id"`
	Tenant    *Tenant   `gorm:"foreignKey:TenantID" json:"tenant,omitempty"`
	Action    string    `gorm:"not null" json:"action"`
	Resource  string    `gorm:"not null" json:"resource"`
	Details   string    `gorm:"type:text" json:"details"`
	IPAddress string    `json:"ip_address"`
	UserAgent string    `json:"user_agent"`
	CreatedAt time.Time `json:"created_at"`
}

type ApiKey struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Name      string    `gorm:"not null" json:"name"`
	Key       string    `gorm:"uniqueIndex;not null" json:"key"`
	UserID    uuid.UUID `gorm:"type:uuid;not null" json:"user_id"`
	User      User      `gorm:"foreignKey:UserID" json:"user,omitempty"`
	TenantID  *uuid.UUID `gorm:"type:uuid" json:"tenant_id"`
	Tenant    *Tenant   `gorm:"foreignKey:TenantID" json:"tenant,omitempty"`
	IsActive  bool      `gorm:"default:true" json:"is_active"`
	ExpiresAt *time.Time `json:"expires_at"`
	LastUsed  *time.Time `json:"last_used"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type Subscription struct {
	ID              uuid.UUID          `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	TenantID        uuid.UUID          `gorm:"type:uuid;not null" json:"tenant_id"`
	Tenant          Tenant             `gorm:"foreignKey:TenantID" json:"tenant,omitempty"`
	Plan            TenantPlan         `gorm:"not null" json:"plan"`
	Status          SubscriptionStatus `gorm:"default:'active'" json:"status"`
	PricePerMonth   float64            `json:"price_per_month"`
	MaxServices     int                `json:"max_services"`
	BillingCycle    string             `gorm:"default:'monthly'" json:"billing_cycle"`
	CurrentPeriodStart time.Time       `json:"current_period_start"`
	CurrentPeriodEnd   time.Time       `json:"current_period_end"`
	CancelAtPeriodEnd  bool            `gorm:"default:false" json:"cancel_at_period_end"`
	CreatedAt       time.Time          `json:"created_at"`
	UpdatedAt       time.Time          `json:"updated_at"`
}

type SubscriptionStatus string

const (
	SubscriptionStatusActive   SubscriptionStatus = "active"
	SubscriptionStatusCanceled SubscriptionStatus = "canceled"
	SubscriptionStatusExpired  SubscriptionStatus = "expired"
	SubscriptionStatusPending  SubscriptionStatus = "pending"
)

// BeforeCreate hook to set default values
func (u *User) BeforeCreate(tx *gorm.DB) error {
	if u.ID == uuid.Nil {
		u.ID = uuid.New()
	}
	return nil
}

func (t *Tenant) BeforeCreate(tx *gorm.DB) error {
	if t.ID == uuid.Nil {
		t.ID = uuid.New()
	}
	return nil
}

func (s *Service) BeforeCreate(tx *gorm.DB) error {
	if s.ID == uuid.Nil {
		s.ID = uuid.New()
	}
	return nil
}
