package main

import (
	"log"
	"os"

	"nomad-services-api/internal/api"
	"nomad-services-api/internal/config"
	"nomad-services-api/internal/database"
	"nomad-services-api/internal/services"

	"github.com/joho/godotenv"
	"github.com/sirupsen/logrus"
)

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		logrus.Info("No .env file found, using system environment variables")
	}

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatal("Failed to load configuration:", err)
	}

	// Setup logging
	setupLogging(cfg)

	// Initialize database
	db, err := database.Initialize(cfg)
	if err != nil {
		log.Fatal("Failed to initialize database:", err)
	}

	// Initialize services
	nomadService := services.NewNomadService(cfg)
	userService := services.NewUserService(db)
	authService := services.NewAuthService(cfg, userService)
	serviceManager := services.NewServiceManager(nomadService, cfg)
	serviceManager.SetDB(db)

	// Initialize API server
	server := api.NewServer(cfg, authService, serviceManager, userService)

	// Start server
	logrus.Infof("Starting server on port %s", cfg.Server.Port)
	if err := server.Start(); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

func setupLogging(cfg *config.Config) {
	level, err := logrus.ParseLevel(cfg.Server.LogLevel)
	if err != nil {
		level = logrus.InfoLevel
	}
	logrus.SetLevel(level)

	if cfg.Server.Environment == "production" {
		logrus.SetFormatter(&logrus.JSONFormatter{})
	} else {
		logrus.SetFormatter(&logrus.TextFormatter{
			FullTimestamp: true,
			ForceColors:   true,
		})
	}

	if cfg.Server.LogFile != "" {
		file, err := os.OpenFile(cfg.Server.LogFile, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
		if err != nil {
			logrus.Warn("Failed to open log file, using stdout")
		} else {
			logrus.SetOutput(file)
		}
	}
}
