module nomad-services-api

go 1.21

require (
	github.com/gin-gonic/gin v1.9.1
	github.com/gin-contrib/cors v1.4.0
	github.com/golang-jwt/jwt/v5 v5.0.0
	github.com/hashicorp/nomad/api v0.0.0-20230922100329-93b3bb1b6b7e
	github.com/joho/godotenv v1.4.0
	github.com/lib/pq v1.10.9
	github.com/golang-migrate/migrate/v4 v4.16.2
	github.com/google/uuid v1.3.1
	github.com/sirupsen/logrus v1.9.3
	github.com/stretchr/testify v1.8.4
	golang.org/x/crypto v0.13.0
	gorm.io/driver/postgres v1.5.2
	gorm.io/gorm v1.25.4
)
