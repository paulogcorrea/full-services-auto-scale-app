package config

import (
	"os"
	"strconv"
	"time"
)

type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	JWT      JWTConfig
	Nomad    NomadConfig
	SaaS     SaaSConfig
}

type ServerConfig struct {
	Port        string
	Environment string
	LogLevel    string
	LogFile     string
	CORSOrigins []string
}

type DatabaseConfig struct {
	Host     string
	Port     string
	User     string
	Password string
	DBName   string
	SSLMode  string
}

type JWTConfig struct {
	Secret         string
	TokenDuration  time.Duration
	RefreshDuration time.Duration
}

type NomadConfig struct {
	Address   string
	JobsPath  string
	Namespace string
	Token     string
}

type SaaSConfig struct {
	MultiTenant     bool
	MaxServicesPerTenant int
	PricingEnabled  bool
	BillingEnabled  bool
}

func Load() (*Config, error) {
	return &Config{
		Server: ServerConfig{
			Port:        getEnv("SERVER_PORT", "8080"),
			Environment: getEnv("ENVIRONMENT", "development"),
			LogLevel:    getEnv("LOG_LEVEL", "info"),
			LogFile:     getEnv("LOG_FILE", ""),
			CORSOrigins: []string{
				getEnv("CORS_ORIGINS", "http://localhost:4200,http://localhost:3000"),
			},
		},
		Database: DatabaseConfig{
			Host:     getEnv("DB_HOST", "localhost"),
			Port:     getEnv("DB_PORT", "5432"),
			User:     getEnv("DB_USER", "postgres"),
			Password: getEnv("DB_PASSWORD", "postgres"),
			DBName:   getEnv("DB_NAME", "nomad_services"),
			SSLMode:  getEnv("DB_SSL_MODE", "disable"),
		},
		JWT: JWTConfig{
			Secret:          getEnv("JWT_SECRET", "your-secret-key-change-in-production"),
			TokenDuration:   getDurationEnv("JWT_TOKEN_DURATION", 24*time.Hour),
			RefreshDuration: getDurationEnv("JWT_REFRESH_DURATION", 7*24*time.Hour),
		},
		Nomad: NomadConfig{
			Address:   getEnv("NOMAD_ADDR", "http://127.0.0.1:4646"),
			JobsPath:  getEnv("NOMAD_JOBS_PATH", "../jobs"),
			Namespace: getEnv("NOMAD_NAMESPACE", "default"),
			Token:     getEnv("NOMAD_TOKEN", ""),
		},
		SaaS: SaaSConfig{
			MultiTenant:          getBoolEnv("SAAS_MULTI_TENANT", false),
			MaxServicesPerTenant: getIntEnv("SAAS_MAX_SERVICES_PER_TENANT", 50),
			PricingEnabled:       getBoolEnv("SAAS_PRICING_ENABLED", false),
			BillingEnabled:       getBoolEnv("SAAS_BILLING_ENABLED", false),
		},
	}, nil
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getIntEnv(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intVal, err := strconv.Atoi(value); err == nil {
			return intVal
		}
	}
	return defaultValue
}

func getBoolEnv(key string, defaultValue bool) bool {
	if value := os.Getenv(key); value != "" {
		if boolVal, err := strconv.ParseBool(value); err == nil {
			return boolVal
		}
	}
	return defaultValue
}

func getDurationEnv(key string, defaultValue time.Duration) time.Duration {
	if value := os.Getenv(key); value != "" {
		if duration, err := time.ParseDuration(value); err == nil {
			return duration
		}
	}
	return defaultValue
}
