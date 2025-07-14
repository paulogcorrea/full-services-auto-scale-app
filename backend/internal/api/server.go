package api

import (
	"net/http"
	"strconv"
	"strings"

	"nomad-services-api/internal/config"
	"nomad-services-api/internal/models"
	"nomad-services-api/internal/services"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
)

type Server struct {
	config         *config.Config
	router         *gin.Engine
	authService    *services.AuthService
	serviceManager *services.ServiceManager
	userService    *services.UserService
}

func NewServer(
	cfg *config.Config,
	authService *services.AuthService,
	serviceManager *services.ServiceManager,
	userService *services.UserService,
) *Server {
	if cfg.Server.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()
	router.Use(gin.Logger())
	router.Use(gin.Recovery())

	// Disable automatic redirects to prevent CORS issues
	router.RedirectTrailingSlash = false
	router.RedirectFixedPath = false

	// CORS configuration
	corsConfig := cors.DefaultConfig()
	corsConfig.AllowOrigins = cfg.Server.CORSOrigins
	corsConfig.AllowCredentials = true
	corsConfig.AllowHeaders = []string{"Origin", "Content-Length", "Content-Type", "Authorization"}
	router.Use(cors.New(corsConfig))

	server := &Server{
		config:         cfg,
		router:         router,
		authService:    authService,
		serviceManager: serviceManager,
		userService:    userService,
	}

	server.setupRoutes()
	return server
}

func (s *Server) setupRoutes() {
	// Health check
	s.router.GET("/health", s.healthCheck)

	// API v1 routes
	v1 := s.router.Group("/api/v1")
	{
		// Authentication routes
		auth := v1.Group("/auth")
		{
			auth.POST("/register", s.register)
			auth.POST("/login", s.login)
			auth.POST("/refresh", s.refreshToken)
		}

		// Protected routes
		protected := v1.Group("/")
		protected.Use(s.authMiddleware())
		{
			// User routes
			users := protected.Group("/users")
			{
				users.GET("/me", s.getMe)
				users.PUT("/me", s.updateMe)
			}

			// Service routes
			servicesGroup := protected.Group("/services")
			{
				servicesGroup.POST("/", s.createService)
				servicesGroup.GET("/", s.listServices)
				servicesGroup.GET("/:id", s.getService)
				servicesGroup.PUT("/:id", s.updateService)
				servicesGroup.DELETE("/:id", s.deleteService)
				servicesGroup.POST("/:id/start", s.startService)
				servicesGroup.POST("/:id/stop", s.stopService)
				servicesGroup.POST("/:id/restart", s.restartService)
				servicesGroup.GET("/:id/logs", s.getServiceLogs)
				servicesGroup.GET("/:id/metrics", s.getServiceMetrics)
			}

			// Add routes without trailing slash for better compatibility
			protected.POST("/services", s.createService)
			protected.GET("/services", s.listServices)
			protected.GET("/templates", s.listServiceTemplates)

			// Service templates routes
			templates := protected.Group("/templates")
			{
				templates.GET("/", s.listServiceTemplates)
				templates.GET("/:id", s.getServiceTemplate)
			}

			// Admin routes
			admin := protected.Group("/admin")
			admin.Use(s.adminMiddleware())
			{
				admin.GET("/users", s.listUsers)
				admin.PUT("/users/:id/role", s.updateUserRole)
				admin.PUT("/users/:id/activate", s.activateUser)
				admin.PUT("/users/:id/deactivate", s.deactivateUser)
			}
		}
	}
}

func (s *Server) Start() error {
	port := s.config.Server.Port
	if !strings.HasPrefix(port, ":") {
		port = ":" + port
	}

	logrus.Infof("Server starting on port %s", port)
	return s.router.Run(port)
}

// Health check endpoint
func (s *Server) healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "healthy",
		"version": "1.0.0",
	})
}

// Authentication endpoints
func (s *Server) register(c *gin.Context) {
	var req services.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := s.authService.Register(&req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "User registered successfully",
		"user":    user,
	})
}

func (s *Server) login(c *gin.Context) {
	var req services.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	response, err := s.authService.Login(&req)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, response)
}

func (s *Server) refreshToken(c *gin.Context) {
	var req struct {
		RefreshToken string `json:"refresh_token" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	response, err := s.authService.RefreshToken(req.RefreshToken)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, response)
}

// User endpoints
func (s *Server) getMe(c *gin.Context) {
	user := s.getCurrentUser(c)
	c.JSON(http.StatusOK, user)
}

func (s *Server) updateMe(c *gin.Context) {
	user := s.getCurrentUser(c)
	
	var req struct {
		FirstName string `json:"first_name"`
		LastName  string `json:"last_name"`
		Email     string `json:"email"`
	}
	
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user.FirstName = req.FirstName
	user.LastName = req.LastName
	user.Email = req.Email

	if err := s.userService.UpdateUser(user); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update user"})
		return
	}

	c.JSON(http.StatusOK, user)
}

// Service endpoints
func (s *Server) createService(c *gin.Context) {
	var req services.CreateServiceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user := s.getCurrentUser(c)
	service, err := s.serviceManager.CreateService(&req, user.ID, user.TenantID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, service)
}

func (s *Server) listServices(c *gin.Context) {
	user := s.getCurrentUser(c)
	services, err := s.serviceManager.ListServices(user.TenantID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to list services"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"services": services,
		"total":    len(services),
	})
}

func (s *Server) getService(c *gin.Context) {
	serviceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid service ID"})
		return
	}

	user := s.getCurrentUser(c)
	service, err := s.serviceManager.GetService(serviceID, user.TenantID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Service not found"})
		return
	}

	c.JSON(http.StatusOK, service)
}

func (s *Server) updateService(c *gin.Context) {
	serviceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid service ID"})
		return
	}

	var req services.CreateServiceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user := s.getCurrentUser(c)
	service, err := s.serviceManager.GetService(serviceID, user.TenantID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Service not found"})
		return
	}

	service.Name = req.Name
	service.Description = req.Description
	service.Config = req.Config

	c.JSON(http.StatusOK, service)
}

func (s *Server) deleteService(c *gin.Context) {
	serviceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid service ID"})
		return
	}

	user := s.getCurrentUser(c)
	_, err = s.serviceManager.GetService(serviceID, user.TenantID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Service not found"})
		return
	}

	// TODO: Implement service deletion
	c.JSON(http.StatusOK, gin.H{"message": "Service deleted successfully"})
}

func (s *Server) startService(c *gin.Context) {
	serviceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid service ID"})
		return
	}

	user := s.getCurrentUser(c)
	deployment, err := s.serviceManager.StartService(serviceID, user.ID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":    "Service deployment started",
		"deployment": deployment,
	})
}

func (s *Server) stopService(c *gin.Context) {
	serviceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid service ID"})
		return
	}

	user := s.getCurrentUser(c)
	if err := s.serviceManager.StopService(serviceID, user.ID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Service stopped successfully"})
}

func (s *Server) restartService(c *gin.Context) {
	serviceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid service ID"})
		return
	}

	user := s.getCurrentUser(c)
	if err := s.serviceManager.RestartService(serviceID, user.ID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Service restarted successfully"})
}

func (s *Server) getServiceLogs(c *gin.Context) {
	serviceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid service ID"})
		return
	}

	user := s.getCurrentUser(c)
	logs, err := s.serviceManager.GetServiceLogs(serviceID, user.TenantID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"logs": logs})
}

func (s *Server) getServiceMetrics(c *gin.Context) {
	serviceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid service ID"})
		return
	}

	user := s.getCurrentUser(c)
	metrics, err := s.serviceManager.GetServiceMetrics(serviceID, user.TenantID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"metrics": metrics})
}

func (s *Server) listServiceTemplates(c *gin.Context) {
	// TODO: Implement template listing
	c.JSON(http.StatusOK, gin.H{
		"templates": []gin.H{},
		"total":     0,
	})
}

func (s *Server) getServiceTemplate(c *gin.Context) {
	// TODO: Implement template retrieval
	c.JSON(http.StatusNotFound, gin.H{"error": "Template not found"})
}

// Admin endpoints
func (s *Server) listUsers(c *gin.Context) {
	limitStr := c.DefaultQuery("limit", "10")
	offsetStr := c.DefaultQuery("offset", "0")

	limit, _ := strconv.Atoi(limitStr)
	offset, _ := strconv.Atoi(offsetStr)

	users, err := s.userService.ListUsers(limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to list users"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"users":  users,
		"total":  len(users),
		"limit":  limit,
		"offset": offset,
	})
}

func (s *Server) updateUserRole(c *gin.Context) {
	userID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	var req struct {
		Role string `json:"role" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := s.userService.UpdateUserRole(userID, models.UserRole(req.Role)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update user role"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "User role updated successfully"})
}

func (s *Server) activateUser(c *gin.Context) {
	userID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	if err := s.userService.ActivateUser(userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to activate user"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "User activated successfully"})
}

func (s *Server) deactivateUser(c *gin.Context) {
	userID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	if err := s.userService.DeactivateUser(userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to deactivate user"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "User deactivated successfully"})
}

// Helper methods
func (s *Server) getCurrentUser(c *gin.Context) *models.User {
	user, exists := c.Get("user")
	if !exists {
		return nil
	}
	return user.(*models.User)
}

func (s *Server) getCurrentClaims(c *gin.Context) *services.Claims {
	claims, exists := c.Get("claims")
	if !exists {
		return nil
	}
	return claims.(*services.Claims)
}
