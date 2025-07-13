package api

import (
	"fmt"
	"net/http"
	"strings"
	"time"

	"nomad-services-api/internal/models"

	"github.com/gin-gonic/gin"
)

// authMiddleware validates JWT tokens and sets user context
func (s *Server) authMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header required"})
			c.Abort()
			return
		}

		// Extract token from "Bearer <token>"
		tokenParts := strings.Split(authHeader, " ")
		if len(tokenParts) != 2 || tokenParts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid authorization header format"})
			c.Abort()
			return
		}

		token := tokenParts[1]

		// Validate token
		claims, err := s.authService.ValidateToken(token)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
			c.Abort()
			return
		}

		// Get user from database
		user, err := s.userService.GetUserByID(claims.UserID)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found"})
			c.Abort()
			return
		}

		// Check if user is active
		if !user.IsActive {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Account is inactive"})
			c.Abort()
			return
		}

		// Set user and claims in context
		c.Set("user", user)
		c.Set("claims", claims)
		c.Set("user_id", user.ID)
		c.Set("tenant_id", user.TenantID)

		c.Next()
	}
}

// adminMiddleware ensures only admin users can access certain endpoints
func (s *Server) adminMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		user := s.getCurrentUser(c)
		if user == nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found in context"})
			c.Abort()
			return
		}

		if user.Role != models.UserRoleAdmin {
			c.JSON(http.StatusForbidden, gin.H{"error": "Admin access required"})
			c.Abort()
			return
		}

		c.Next()
	}
}

// tenantAdminMiddleware ensures only tenant admins or system admins can access certain endpoints
func (s *Server) tenantAdminMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		user := s.getCurrentUser(c)
		if user == nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found in context"})
			c.Abort()
			return
		}

		if user.Role != models.UserRoleAdmin && user.Role != models.UserRoleTenantAdmin {
			c.JSON(http.StatusForbidden, gin.H{"error": "Admin access required"})
			c.Abort()
			return
		}

		c.Next()
	}
}

// corsMiddleware handles CORS headers (already handled by gin-contrib/cors, but keeping for reference)
func (s *Server) corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		origin := c.Request.Header.Get("Origin")
		
		// Check if origin is allowed
		allowed := false
		for _, allowedOrigin := range s.config.Server.CORSOrigins {
			if origin == allowedOrigin {
				allowed = true
				break
			}
		}

		if allowed {
			c.Header("Access-Control-Allow-Origin", origin)
		}
		
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Authorization")
		c.Header("Access-Control-Allow-Credentials", "true")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}

// loggingMiddleware logs request details (already handled by gin.Logger(), but keeping for reference)
func (s *Server) loggingMiddleware() gin.HandlerFunc {
	return gin.LoggerWithFormatter(func(param gin.LogFormatterParams) string {
		return fmt.Sprintf("%s - [%s] \"%s %s %s %d %s \"%s\" %s\"\n",
			param.ClientIP,
			param.TimeStamp.Format("02/Jan/2006:15:04:05 -0700"),
			param.Method,
			param.Path,
			param.Request.Proto,
			param.StatusCode,
			param.Latency,
			param.Request.UserAgent(),
			param.ErrorMessage,
		)
	})
}

// rateLimitMiddleware implements basic rate limiting (simple implementation)
func (s *Server) rateLimitMiddleware() gin.HandlerFunc {
	// This is a simple implementation. For production, consider using redis-based rate limiting
	return func(c *gin.Context) {
		// TODO: Implement rate limiting logic
		// For now, just pass through
		c.Next()
	}
}

// requestIDMiddleware adds a unique request ID to each request
func (s *Server) requestIDMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := c.GetHeader("X-Request-ID")
		if requestID == "" {
			// Generate a simple request ID (in production, use UUID)
			requestID = fmt.Sprintf("%d", time.Now().UnixNano())
		}
		
		c.Header("X-Request-ID", requestID)
		c.Set("request_id", requestID)
		c.Next()
	}
}

// errorHandlerMiddleware handles errors consistently
func (s *Server) errorHandlerMiddleware() gin.HandlerFunc {
	return gin.Recovery()
}

// securityHeadersMiddleware adds security headers
func (s *Server) securityHeadersMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("X-Content-Type-Options", "nosniff")
		c.Header("X-Frame-Options", "DENY")
		c.Header("X-XSS-Protection", "1; mode=block")
		c.Header("Referrer-Policy", "strict-origin-when-cross-origin")
		
		if s.config.Server.Environment == "production" {
			c.Header("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
		}
		
		c.Next()
	}
}
