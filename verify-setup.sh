#!/bin/bash

# Verification Script for ClearportX AMM Canton Repository
# Checks that all components are properly configured

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     ClearportX AMM Canton - Setup Verification            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

PROJECT_ROOT="/root/clearportx-amm-canton"
cd "$PROJECT_ROOT"

errors=0
warnings=0

# ============================================================================
# Check Prerequisites
# ============================================================================

echo -e "${CYAN}Checking prerequisites...${NC}"

# DAML SDK
if command -v daml &> /dev/null; then
    daml_version=$(daml version 2>&1 | head -1 | awk '{print $3}')
    echo -e "${GREEN}✓${NC} DAML SDK: $daml_version"
else
    echo -e "${RED}✗${NC} DAML SDK not found"
    echo -e "  Install: curl -sSL https://get.daml.com/ | sh"
    ((errors++))
fi

# Java
if command -v java &> /dev/null; then
    java_version=$(java -version 2>&1 | head -1 | cut -d'"' -f2)
    echo -e "${GREEN}✓${NC} Java: $java_version"

    if [[ ! "$java_version" =~ ^17 ]]; then
        echo -e "${YELLOW}⚠${NC}  Java 17 recommended (current: $java_version)"
        ((warnings++))
    fi
else
    echo -e "${RED}✗${NC} Java not found"
    ((errors++))
fi

# Node.js
if command -v node &> /dev/null; then
    node_version=$(node --version)
    echo -e "${GREEN}✓${NC} Node.js: $node_version"
else
    echo -e "${RED}✗${NC} Node.js not found"
    ((errors++))
fi

# Docker
if command -v docker &> /dev/null; then
    docker_version=$(docker --version | awk '{print $3}' | tr -d ',')
    echo -e "${GREEN}✓${NC} Docker: $docker_version"
else
    echo -e "${YELLOW}⚠${NC}  Docker not found (optional)"
    ((warnings++))
fi

# ============================================================================
# Check Project Structure
# ============================================================================

echo -e "\n${CYAN}Checking project structure...${NC}"

required_dirs=(
    "daml"
    "daml/AMM"
    "daml/Token"
    "daml/LPToken"
    "daml/Init"
    "backend"
    "backend/src/main/java/com/clearportx"
    "frontend"
    "frontend/src"
    "infrastructure"
    "infrastructure/canton"
    "infrastructure/docker"
    "infrastructure/scripts"
    "devops"
    "docs"
    "test"
    "config"
)

for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓${NC} $dir/"
    else
        echo -e "${RED}✗${NC} $dir/ missing"
        ((errors++))
    fi
done

# ============================================================================
# Check Essential Files
# ============================================================================

echo -e "\n${CYAN}Checking essential files...${NC}"

required_files=(
    "README.md"
    "Makefile"
    "package.json"
    "docker-compose.yml"
    ".gitignore"
    "LICENSE"
    "daml/daml.yaml"
    "backend/build.gradle.kts"
    "frontend/package.json"
    "infrastructure/scripts/deploy-local.sh"
    "docs/ARCHITECTURE.md"
    "docs/DEPLOYMENT.md"
    "docs/TROUBLESHOOTING.md"
    "config/.env.example"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
    else
        echo -e "${RED}✗${NC} $file missing"
        ((errors++))
    fi
done

# ============================================================================
# Check DAML Contracts
# ============================================================================

echo -e "\n${CYAN}Checking DAML contracts...${NC}"

daml_contracts=(
    "daml/AMM/Pool.daml"
    "daml/AMM/Types.daml"
    "daml/AMM/PoolAnnouncement.daml"
    "daml/Token/Token.daml"
    "daml/LPToken/LPToken.daml"
    "daml/Init/DevNetInit.daml"
)

for contract in "${daml_contracts[@]}"; do
    if [ -f "$contract" ]; then
        echo -e "${GREEN}✓${NC} $contract"
    else
        echo -e "${YELLOW}⚠${NC}  $contract missing"
        ((warnings++))
    fi
done

# ============================================================================
# Check Configuration
# ============================================================================

echo -e "\n${CYAN}Checking configuration...${NC}"

if [ -f ".env" ]; then
    echo -e "${GREEN}✓${NC} .env file exists"

    # Check required variables
    required_vars=(
        "CANTON_PARTICIPANT_HOST"
        "BACKEND_PORT"
    )

    for var in "${required_vars[@]}"; do
        if grep -q "^$var=" .env 2>/dev/null; then
            echo -e "${GREEN}✓${NC}   $var configured"
        else
            echo -e "${YELLOW}⚠${NC}   $var not set in .env"
            ((warnings++))
        fi
    done
else
    echo -e "${YELLOW}⚠${NC}  .env file not found"
    echo -e "  Run: cp config/.env.example .env"
    ((warnings++))
fi

# ============================================================================
# Check Dependencies
# ============================================================================

echo -e "\n${CYAN}Checking dependencies...${NC}"

# Backend dependencies
if [ -f "backend/build.gradle.kts" ]; then
    echo -e "${GREEN}✓${NC} Backend build configuration exists"
else
    echo -e "${RED}✗${NC} Backend build.gradle.kts missing"
    ((errors++))
fi

# Frontend dependencies
if [ -f "frontend/package.json" ]; then
    echo -e "${GREEN}✓${NC} Frontend package.json exists"

    if [ -d "frontend/node_modules" ]; then
        echo -e "${GREEN}✓${NC}   node_modules installed"
    else
        echo -e "${YELLOW}⚠${NC}   node_modules not installed"
        echo -e "  Run: cd frontend && npm install"
        ((warnings++))
    fi
else
    echo -e "${RED}✗${NC} Frontend package.json missing"
    ((errors++))
fi

# ============================================================================
# Check Executability
# ============================================================================

echo -e "\n${CYAN}Checking script permissions...${NC}"

scripts=(
    "infrastructure/scripts/deploy-local.sh"
    "infrastructure/scripts/deploy-devnet.sh"
    "infrastructure/scripts/init-pools.sh"
    "migrate-from-cn-quickstart.sh"
)

for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            echo -e "${GREEN}✓${NC} $script (executable)"
        else
            echo -e "${YELLOW}⚠${NC}  $script (not executable)"
            chmod +x "$script"
            echo -e "  Fixed: chmod +x $script"
        fi
    fi
done

# ============================================================================
# Test DAML Build
# ============================================================================

echo -e "\n${CYAN}Testing DAML build...${NC}"

cd daml
if daml build > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} DAML build successful"

    if [ -f ".daml/dist/clearportx-amm-1.0.0.dar" ]; then
        dar_size=$(ls -lh .daml/dist/clearportx-amm-1.0.0.dar | awk '{print $5}')
        echo -e "${GREEN}✓${NC}   DAR file created ($dar_size)"
    fi
else
    echo -e "${RED}✗${NC} DAML build failed"
    echo -e "  Check: cd daml && daml build"
    ((errors++))
fi
cd "$PROJECT_ROOT"

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                     Verification Summary                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
    echo -e "\n${CYAN}Ready to start development:${NC}"
    echo -e "  1. make build        # Build all components"
    echo -e "  2. make test         # Run tests"
    echo -e "  3. make start        # Start services"
    echo ""
    exit 0
elif [ $errors -eq 0 ]; then
    echo -e "${YELLOW}⚠️  ${warnings} warnings found${NC}"
    echo -e "\n${CYAN}System is functional but has minor issues.${NC}"
    echo -e "Review warnings above and fix if needed."
    echo ""
    exit 0
else
    echo -e "${RED}❌ ${errors} errors found${NC}"
    if [ $warnings -gt 0 ]; then
        echo -e "${YELLOW}⚠️  ${warnings} warnings found${NC}"
    fi
    echo -e "\n${CYAN}Fix errors before proceeding:${NC}"
    echo -e "  1. Install missing prerequisites"
    echo -e "  2. Run: make setup"
    echo -e "  3. Configure .env file"
    echo -e "  4. Re-run: ./verify-setup.sh"
    echo ""
    exit 1
fi
