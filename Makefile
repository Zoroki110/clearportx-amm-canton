.PHONY: help build test clean deploy start stop logs init-local init-devnet

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
CYAN := \033[0;36m
NC := \033[0m

# Project Configuration
PROJECT_NAME := clearportx-amm-canton
VERSION := 1.0.0
DAR_NAME := clearportx-amm-$(VERSION)

help:
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║          ClearportX AMM - Command Reference                ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)Development Commands:$(NC)"
	@echo "  $(GREEN)make setup$(NC)          - Initial project setup"
	@echo "  $(GREEN)make build$(NC)          - Build all components"
	@echo "  $(GREEN)make test$(NC)           - Run all tests"
	@echo "  $(GREEN)make start$(NC)          - Start all services (Docker)"
	@echo "  $(GREEN)make stop$(NC)           - Stop all services"
	@echo "  $(GREEN)make clean$(NC)          - Clean build artifacts"
	@echo ""
	@echo "$(CYAN)DAML Commands:$(NC)"
	@echo "  $(GREEN)make daml-build$(NC)     - Build DAML contracts"
	@echo "  $(GREEN)make daml-test$(NC)      - Run DAML tests"
	@echo "  $(GREEN)make daml-clean$(NC)     - Clean DAML artifacts"
	@echo ""
	@echo "$(CYAN)Backend Commands:$(NC)"
	@echo "  $(GREEN)make backend-build$(NC)  - Build backend service"
	@echo "  $(GREEN)make backend-test$(NC)   - Run backend tests"
	@echo "  $(GREEN)make backend-run$(NC)    - Run backend locally"
	@echo ""
	@echo "$(CYAN)Frontend Commands:$(NC)"
	@echo "  $(GREEN)make frontend-build$(NC) - Build frontend"
	@echo "  $(GREEN)make frontend-dev$(NC)   - Run frontend dev server"
	@echo "  $(GREEN)make frontend-test$(NC)  - Run frontend tests"
	@echo ""
	@echo "$(CYAN)Deployment Commands:$(NC)"
	@echo "  $(GREEN)make deploy-local$(NC)   - Deploy to local Canton"
	@echo "  $(GREEN)make deploy-devnet$(NC)  - Deploy to Canton DevNet"
	@echo "  $(GREEN)make deploy-mainnet$(NC) - Deploy to Canton MainNet"
	@echo ""
	@echo "$(CYAN)Docker Commands:$(NC)"
	@echo "  $(GREEN)make docker-build$(NC)   - Build Docker images"
	@echo "  $(GREEN)make docker-up$(NC)      - Start Docker Compose"
	@echo "  $(GREEN)make docker-down$(NC)    - Stop Docker Compose"
	@echo "  $(GREEN)make docker-logs$(NC)    - View Docker logs"
	@echo ""
	@echo "$(CYAN)Utility Commands:$(NC)"
	@echo "  $(GREEN)make init-local$(NC)     - Initialize local environment"
	@echo "  $(GREEN)make init-devnet$(NC)    - Initialize DevNet environment"
	@echo "  $(GREEN)make logs$(NC)           - View application logs"
	@echo "  $(GREEN)make health$(NC)         - Check service health"
	@echo ""

# ============================================================================
# Setup
# ============================================================================

setup:
	@echo "$(YELLOW)Setting up ClearportX AMM...$(NC)"
	@mkdir -p logs
	@cp config/.env.example .env || true
	@echo "$(GREEN)✅ Setup complete. Edit .env with your configuration.$(NC)"

check-deps:
	@printf "$(CYAN)→$(NC) Checking dependencies...\n"
	@command -v daml >/dev/null 2>&1 || (echo "$(RED)✗ DAML SDK not found$(NC)" && exit 1)
	@command -v java >/dev/null 2>&1 || (echo "$(RED)✗ Java not found$(NC)" && exit 1)
	@command -v node >/dev/null 2>&1 || (echo "$(RED)✗ Node.js not found$(NC)" && exit 1)
	@command -v docker >/dev/null 2>&1 || (echo "$(RED)✗ Docker not found$(NC)" && exit 1)
	@echo "$(GREEN)✅ All dependencies installed$(NC)"

# ============================================================================
# Build Commands
# ============================================================================

build: daml-build backend-build frontend-build
	@echo "$(GREEN)✅ All components built successfully$(NC)"

daml-build:
	@echo "$(YELLOW)Building DAML contracts...$(NC)"
	@cd daml && daml build
	@echo "$(GREEN)✅ DAML build complete: daml/.daml/dist/$(DAR_NAME).dar$(NC)"

backend-build:
	@echo "$(YELLOW)Building backend service...$(NC)"
	@cd backend && ./gradlew clean build -x test
	@echo "$(GREEN)✅ Backend build complete$(NC)"

frontend-build:
	@echo "$(YELLOW)Building frontend...$(NC)"
	@cd frontend && npm install && npm run build
	@echo "$(GREEN)✅ Frontend build complete$(NC)"

# ============================================================================
# Test Commands
# ============================================================================

test: daml-test backend-test frontend-test
	@echo "$(GREEN)✅ All tests passed$(NC)"

daml-test:
	@echo "$(YELLOW)Running DAML tests...$(NC)"
	@cd daml && daml test

backend-test:
	@echo "$(YELLOW)Running backend tests...$(NC)"
	@cd backend && ./gradlew test

backend-integration-test:
	@echo "$(YELLOW)Running backend integration tests...$(NC)"
	@cd backend && ./gradlew integrationTest

frontend-test:
	@echo "$(YELLOW)Running frontend tests...$(NC)"
	@cd frontend && npm test

e2e-test:
	@echo "$(YELLOW)Running end-to-end tests...$(NC)"
	@./test/e2e/run-tests.sh

# ============================================================================
# Run Commands
# ============================================================================

backend-run:
	@echo "$(YELLOW)Starting backend service...$(NC)"
	@cd backend && ./gradlew bootRun

frontend-dev:
	@echo "$(YELLOW)Starting frontend dev server...$(NC)"
	@cd frontend && npm run dev

start: docker-up

stop: docker-down

# ============================================================================
# Docker Commands
# ============================================================================

docker-build:
	@echo "$(YELLOW)Building Docker images...$(NC)"
	@docker-compose build
	@echo "$(GREEN)✅ Docker images built$(NC)"

docker-up:
	@echo "$(YELLOW)Starting Docker Compose services...$(NC)"
	@docker-compose up -d
	@echo "$(GREEN)✅ Services started$(NC)"
	@echo "$(BLUE)→ Frontend: http://localhost:5173$(NC)"
	@echo "$(BLUE)→ Backend: http://localhost:8080$(NC)"
	@echo "$(BLUE)→ Grafana: http://localhost:3000$(NC)"
	@echo "$(BLUE)→ Prometheus: http://localhost:9091$(NC)"

docker-down:
	@echo "$(YELLOW)Stopping Docker Compose services...$(NC)"
	@docker-compose down
	@echo "$(GREEN)✅ Services stopped$(NC)"

docker-logs:
	@docker-compose logs -f

docker-clean:
	@echo "$(YELLOW)Cleaning Docker resources...$(NC)"
	@docker-compose down -v
	@docker system prune -f
	@echo "$(GREEN)✅ Docker cleaned$(NC)"

# ============================================================================
# Deployment Commands
# ============================================================================

deploy-local: build
	@echo "$(YELLOW)Deploying to local Canton...$(NC)"
	@./infrastructure/scripts/deploy-local.sh
	@echo "$(GREEN)✅ Deployed to local Canton$(NC)"

deploy-devnet: build
	@echo "$(YELLOW)Deploying to Canton DevNet...$(NC)"
	@./infrastructure/scripts/deploy-devnet.sh
	@echo "$(GREEN)✅ Deployed to DevNet$(NC)"

deploy-mainnet: build
	@echo "$(YELLOW)Deploying to Canton MainNet...$(NC)"
	@./infrastructure/scripts/deploy-mainnet.sh
	@echo "$(GREEN)✅ Deployed to MainNet$(NC)"

# ============================================================================
# Initialization Commands
# ============================================================================

init-local: deploy-local
	@echo "$(YELLOW)Initializing local environment...$(NC)"
	@./infrastructure/scripts/init-pools.sh
	@echo "$(GREEN)✅ Local environment initialized$(NC)"

init-devnet:
	@echo "$(YELLOW)Initializing DevNet environment...$(NC)"
	@cd daml && daml script \
		--dar .daml/dist/$(DAR_NAME).dar \
		--script-name Init.DevNetInit:initialize \
		--ledger-host ${CANTON_DEVNET_HOST} \
		--ledger-port ${CANTON_DEVNET_PORT} \
		--access-token-file ${CANTON_DEVNET_TOKEN_FILE}
	@echo "$(GREEN)✅ DevNet initialized$(NC)"

# ============================================================================
# Utility Commands
# ============================================================================

logs:
	@tail -f logs/*.log

health:
	@echo "$(CYAN)Checking service health...$(NC)"
	@curl -s http://localhost:8080/actuator/health | jq . || echo "$(RED)Backend not responding$(NC)"
	@curl -s http://localhost:3902/health || echo "$(RED)Canton not responding$(NC)"

clean: daml-clean
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	@rm -rf backend/build
	@rm -rf frontend/dist
	@rm -rf logs/*.log
	@echo "$(GREEN)✅ Cleaned$(NC)"

daml-clean:
	@cd daml && rm -rf .daml/dist

verify:
	@echo "$(CYAN)Verifying deployment...$(NC)"
	@./infrastructure/scripts/verify-deployment.sh

backup:
	@echo "$(YELLOW)Creating backup...$(NC)"
	@./infrastructure/scripts/backup.sh
	@echo "$(GREEN)✅ Backup complete$(NC)"

# ============================================================================
# Monitoring Commands
# ============================================================================

metrics:
	@curl -s http://localhost:8080/actuator/prometheus

dashboard:
	@echo "$(BLUE)Opening Grafana dashboard...$(NC)"
	@xdg-open http://localhost:3000 2>/dev/null || open http://localhost:3000 2>/dev/null || echo "Open http://localhost:3000"

# ============================================================================
# Database Commands
# ============================================================================

db-migrate:
	@echo "$(YELLOW)Running database migrations...$(NC)"
	@cd backend && ./gradlew flywayMigrate

db-reset:
	@echo "$(YELLOW)Resetting database...$(NC)"
	@cd backend && ./gradlew flywayClean flywayMigrate

# Default target
.DEFAULT_GOAL := help
