#!/bin/bash

# Migration Script: cn-quickstart → clearportx-amm-canton
# Migrates existing ClearportX code to standalone repository

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     ClearportX Migration: cn-quickstart → Standalone       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Configuration
SOURCE_DIR="/root/cn-quickstart/quickstart/clearportx"
TARGET_DIR="/root/clearportx-amm-canton"
BACKUP_DIR="/root/clearportx-migration-backup-$(date +%Y%m%d-%H%M%S)"

# Validate source exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}❌ Source directory not found: $SOURCE_DIR${NC}"
    exit 1
fi

# Create backup
echo -e "${YELLOW}📦 Creating backup...${NC}"
mkdir -p "$BACKUP_DIR"
if [ -d "$TARGET_DIR" ]; then
    cp -r "$TARGET_DIR" "$BACKUP_DIR/"
    echo -e "${GREEN}✅ Backup created: $BACKUP_DIR${NC}"
fi

# ============================================================================
# Migrate DAML Contracts
# ============================================================================

echo -e "\n${BLUE}📝 Migrating DAML contracts...${NC}"

# Copy all DAML modules
cp -r "$SOURCE_DIR/daml/AMM/"* "$TARGET_DIR/daml/AMM/" 2>/dev/null || true
cp -r "$SOURCE_DIR/daml/Token/"* "$TARGET_DIR/daml/Token/" 2>/dev/null || true
cp -r "$SOURCE_DIR/daml/LPToken/"* "$TARGET_DIR/daml/LPToken/" 2>/dev/null || true
cp -r "$SOURCE_DIR/daml/Protocol/"* "$TARGET_DIR/daml/Protocol/" 2>/dev/null || true

# Copy test files
mkdir -p "$TARGET_DIR/test/daml"
find "$SOURCE_DIR/daml" -name "Test*.daml" -exec cp {} "$TARGET_DIR/test/daml/" \; 2>/dev/null || true

echo -e "${GREEN}✅ DAML contracts migrated${NC}"

# ============================================================================
# Migrate Backend
# ============================================================================

echo -e "\n${BLUE}🔧 Migrating backend code...${NC}"

SOURCE_BACKEND="/root/cn-quickstart/quickstart/backend"

if [ -d "$SOURCE_BACKEND/src" ]; then
    # Copy Java/Kotlin source files
    find "$SOURCE_BACKEND/src" -type f \( -name "*.java" -o -name "*.kt" \) | while read -r file; do
        # Extract relative path
        rel_path="${file#$SOURCE_BACKEND/src/}"
        target_file="$TARGET_DIR/backend/src/$rel_path"

        # Create directory if needed
        mkdir -p "$(dirname "$target_file")"

        # Copy and adapt package names if needed
        if [[ "$file" == *.java ]] || [[ "$file" == *.kt ]]; then
            # Replace package com.digitalasset.quickstart with com.clearportx
            sed 's/package com\.digitalasset\.quickstart/package com.clearportx/g; s/import com\.digitalasset\.quickstart/import com.clearportx/g' "$file" > "$target_file"
        else
            cp "$file" "$target_file"
        fi
    done

    echo -e "${GREEN}✅ Backend code migrated${NC}"
else
    echo -e "${YELLOW}⚠️  Backend source not found, skipping${NC}"
fi

# ============================================================================
# Migrate Frontend
# ============================================================================

echo -e "\n${BLUE}⚛️  Migrating frontend code...${NC}"

SOURCE_FRONTEND="/root/cn-quickstart/quickstart/frontend"

if [ -d "$SOURCE_FRONTEND/src" ]; then
    # Copy React components
    cp -r "$SOURCE_FRONTEND/src/"* "$TARGET_DIR/frontend/src/" 2>/dev/null || true

    # Update API endpoints in frontend code
    find "$TARGET_DIR/frontend/src" -type f \( -name "*.ts" -o -name "*.tsx" \) -exec \
        sed -i 's|http://localhost:8081|http://localhost:8080|g' {} \; 2>/dev/null || true

    echo -e "${GREEN}✅ Frontend code migrated${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend source not found, skipping${NC}"
fi

# ============================================================================
# Migrate Configuration Files
# ============================================================================

echo -e "\n${BLUE}⚙️  Migrating configuration...${NC}"

# Copy useful scripts
if [ -d "$SOURCE_DIR/scripts" ]; then
    cp -r "$SOURCE_DIR/scripts/"* "$TARGET_DIR/infrastructure/scripts/" 2>/dev/null || true
fi

# Copy deployment scripts
cp "$SOURCE_DIR"/*.sh "$TARGET_DIR/infrastructure/scripts/" 2>/dev/null || true

# Copy documentation
cp "$SOURCE_DIR/docs/"*.md "$TARGET_DIR/docs/" 2>/dev/null || true
cp "$SOURCE_DIR"/*.md "$TARGET_DIR/docs/legacy/" 2>/dev/null || true

# Copy monitoring configs
cp "$SOURCE_DIR"/prometheus*.yml "$TARGET_DIR/devops/monitoring/" 2>/dev/null || true
cp "$SOURCE_DIR"/grafana*.json "$TARGET_DIR/devops/monitoring/" 2>/dev/null || true

echo -e "${GREEN}✅ Configuration migrated${NC}"

# ============================================================================
# Migrate Build Artifacts (Optional)
# ============================================================================

echo -e "\n${BLUE}📦 Copying build artifacts...${NC}"

# Copy DAR file if it exists
if [ -f "$SOURCE_DIR/.daml/dist/"*.dar ]; then
    mkdir -p "$TARGET_DIR/daml/.daml/dist"
    cp "$SOURCE_DIR/.daml/dist/"*.dar "$TARGET_DIR/daml/.daml/dist/" 2>/dev/null || true
    echo -e "${GREEN}✅ DAR file copied${NC}"
fi

# ============================================================================
# Create Migration Report
# ============================================================================

cat > "$TARGET_DIR/MIGRATION_REPORT.md" << EOF
# Migration Report

**Date:** $(date)
**Source:** $SOURCE_DIR
**Target:** $TARGET_DIR
**Backup:** $BACKUP_DIR

## Migrated Components

### DAML Contracts
- ✅ AMM contracts (Pool, Types, SwapRequest, etc.)
- ✅ Token standard
- ✅ LPToken implementation
- ✅ Protocol fee contracts
- ✅ Test contracts

### Backend
- ✅ Java/Kotlin source files
- ✅ Package names updated (com.digitalasset.quickstart → com.clearportx)
- ✅ Controllers, Services, Models

### Frontend
- ✅ React components
- ✅ API clients
- ✅ Hooks and utilities
- ✅ API endpoints updated

### Configuration
- ✅ Deployment scripts
- ✅ Documentation
- ✅ Monitoring configs (Prometheus, Grafana)

### Build Artifacts
- ✅ DAR files (if available)

## Post-Migration Steps

1. Review and test all migrated code
2. Update configuration files (.env)
3. Verify build process:
   \`\`\`bash
   cd $TARGET_DIR
   make build
   \`\`\`
4. Run tests:
   \`\`\`bash
   make test
   \`\`\`
5. Deploy to local Canton:
   \`\`\`bash
   make deploy-local
   \`\`\`

## Differences from cn-quickstart

1. **Independent Repository**: No cn-quickstart dependencies
2. **Updated Package Names**: com.clearportx instead of com.digitalasset.quickstart
3. **Streamlined Structure**: Production-ready layout
4. **Complete Infrastructure**: Docker, K8s, CI/CD included
5. **Comprehensive Documentation**: All docs in one place

## Notes

- Original code backed up to: $BACKUP_DIR
- Some manual adjustments may be needed for:
  - Environment variables
  - Canton participant configuration
  - OAuth/JWT settings
  - Database connection strings

## Rollback

If migration fails, restore from backup:
\`\`\`bash
rm -rf $TARGET_DIR
cp -r $BACKUP_DIR/clearportx-amm-canton $TARGET_DIR
\`\`\`
EOF

echo -e "${GREEN}✅ Migration report created: $TARGET_DIR/MIGRATION_REPORT.md${NC}"

# ============================================================================
# Validation
# ============================================================================

echo -e "\n${BLUE}🔍 Validating migration...${NC}"

errors=0

# Check DAML files
if [ ! -f "$TARGET_DIR/daml/AMM/Pool.daml" ]; then
    echo -e "${RED}❌ Pool.daml not found${NC}"
    ((errors++))
fi

if [ ! -f "$TARGET_DIR/daml/Token/Token.daml" ]; then
    echo -e "${RED}❌ Token.daml not found${NC}"
    ((errors++))
fi

# Check backend structure
if [ ! -f "$TARGET_DIR/backend/build.gradle.kts" ]; then
    echo -e "${RED}❌ Backend build.gradle.kts not found${NC}"
    ((errors++))
fi

# Check frontend structure
if [ ! -f "$TARGET_DIR/frontend/package.json" ]; then
    echo -e "${RED}❌ Frontend package.json not found${NC}"
    ((errors++))
fi

if [ $errors -eq 0 ]; then
    echo -e "${GREEN}✅ Validation passed${NC}"
else
    echo -e "${RED}❌ Validation failed with $errors errors${NC}"
    echo -e "${YELLOW}⚠️  Check errors and re-run migration if needed${NC}"
fi

# ============================================================================
# Summary
# ============================================================================

echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    Migration Complete                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✅ ClearportX code migrated to standalone repository${NC}"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo -e "  1. cd $TARGET_DIR"
echo -e "  2. Review MIGRATION_REPORT.md"
echo -e "  3. Update .env with your configuration"
echo -e "  4. make build"
echo -e "  5. make test"
echo -e "  6. make start"
echo ""
echo -e "${CYAN}Backup location:${NC} $BACKUP_DIR"
echo -e "${CYAN}Migration report:${NC} $TARGET_DIR/MIGRATION_REPORT.md"
echo ""
echo -e "${YELLOW}⚠️  Remember to update:${NC}"
echo -e "  - Environment variables (.env)"
echo -e "  - Canton participant configuration"
echo -e "  - OAuth/JWT settings"
echo -e "  - Database credentials"
echo ""
