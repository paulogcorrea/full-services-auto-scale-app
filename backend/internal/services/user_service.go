package services

import (
	"fmt"

	"nomad-services-api/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type UserService struct {
	db *gorm.DB
}

func NewUserService(db *gorm.DB) *UserService {
	return &UserService{db: db}
}

// CreateUser creates a new user in the database
func (us *UserService) CreateUser(user *models.User) error {
	return us.db.Create(user).Error
}

// GetUserByID retrieves a user by ID
func (us *UserService) GetUserByID(id uuid.UUID) (*models.User, error) {
	var user models.User
	if err := us.db.Preload("Tenant").First(&user, id).Error; err != nil {
		return nil, fmt.Errorf("user not found: %w", err)
	}
	return &user, nil
}

// GetUserByUsername retrieves a user by username
func (us *UserService) GetUserByUsername(username string) (*models.User, error) {
	var user models.User
	if err := us.db.Preload("Tenant").Where("username = ?", username).First(&user).Error; err != nil {
		return nil, fmt.Errorf("user not found: %w", err)
	}
	return &user, nil
}

// GetUserByEmail retrieves a user by email
func (us *UserService) GetUserByEmail(email string) (*models.User, error) {
	var user models.User
	if err := us.db.Preload("Tenant").Where("email = ?", email).First(&user).Error; err != nil {
		return nil, fmt.Errorf("user not found: %w", err)
	}
	return &user, nil
}

// UpdateUser updates a user in the database
func (us *UserService) UpdateUser(user *models.User) error {
	return us.db.Save(user).Error
}

// DeleteUser deletes a user from the database
func (us *UserService) DeleteUser(id uuid.UUID) error {
	return us.db.Delete(&models.User{}, id).Error
}

// ListUsers retrieves all users (with pagination support)
func (us *UserService) ListUsers(limit, offset int) ([]models.User, error) {
	var users []models.User
	query := us.db.Preload("Tenant").Order("created_at DESC")
	
	if limit > 0 {
		query = query.Limit(limit)
	}
	
	if offset > 0 {
		query = query.Offset(offset)
	}
	
	if err := query.Find(&users).Error; err != nil {
		return nil, fmt.Errorf("failed to list users: %w", err)
	}
	
	return users, nil
}

// GetUsersByTenant retrieves all users for a specific tenant
func (us *UserService) GetUsersByTenant(tenantID uuid.UUID) ([]models.User, error) {
	var users []models.User
	if err := us.db.Where("tenant_id = ?", tenantID).Find(&users).Error; err != nil {
		return nil, fmt.Errorf("failed to get users by tenant: %w", err)
	}
	return users, nil
}

// CountUsers returns the total number of users
func (us *UserService) CountUsers() (int64, error) {
	var count int64
	if err := us.db.Model(&models.User{}).Count(&count).Error; err != nil {
		return 0, fmt.Errorf("failed to count users: %w", err)
	}
	return count, nil
}

// ActivateUser activates a user account
func (us *UserService) ActivateUser(id uuid.UUID) error {
	return us.db.Model(&models.User{}).Where("id = ?", id).Update("is_active", true).Error
}

// DeactivateUser deactivates a user account
func (us *UserService) DeactivateUser(id uuid.UUID) error {
	return us.db.Model(&models.User{}).Where("id = ?", id).Update("is_active", false).Error
}

// AssignUserToTenant assigns a user to a tenant
func (us *UserService) AssignUserToTenant(userID, tenantID uuid.UUID) error {
	return us.db.Model(&models.User{}).Where("id = ?", userID).Update("tenant_id", tenantID).Error
}

// RemoveUserFromTenant removes a user from a tenant
func (us *UserService) RemoveUserFromTenant(userID uuid.UUID) error {
	return us.db.Model(&models.User{}).Where("id = ?", userID).Update("tenant_id", nil).Error
}

// UpdateUserRole updates a user's role
func (us *UserService) UpdateUserRole(userID uuid.UUID, role models.UserRole) error {
	return us.db.Model(&models.User{}).Where("id = ?", userID).Update("role", role).Error
}
