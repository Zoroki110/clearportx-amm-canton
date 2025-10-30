#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     ClearportX AMM - Complete Migration with Frontend     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Paths
CN_QUICKSTART="/root/cn-quickstart/quickstart/clearportx"
CANTON_WEBSITE="/root/canton-website/app"
TARGET_DIR="/root/clearportx-amm-canton"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/tmp/clearportx-backup-${TIMESTAMP}"

echo -e "${BLUE}📁 Paths:${NC}"
echo "  - cn-quickstart: $CN_QUICKSTART"
echo "  - canton-website: $CANTON_WEBSITE"
echo "  - Target: $TARGET_DIR"
echo "  - Backup: $BACKUP_DIR"
echo ""

# Create backup
echo -e "${YELLOW}📦 Creating backup...${NC}"
mkdir -p "$BACKUP_DIR"
if [ -d "$TARGET_DIR/daml" ]; then
    cp -r "$TARGET_DIR" "$BACKUP_DIR/" 2>/dev/null || true
    echo -e "${GREEN}✅ Backup created at $BACKUP_DIR${NC}"
fi

# ============================================================================
# DAML Contracts Migration
# ============================================================================
echo -e "\n${BLUE}Step 1: Migrating DAML Contracts...${NC}"
if [ -d "$CN_QUICKSTART/daml" ]; then
    mkdir -p "$TARGET_DIR/daml"

    # Copy all DAML files
    cp -r "$CN_QUICKSTART/daml/"* "$TARGET_DIR/daml/" 2>/dev/null || true

    # Copy DAR artifacts
    [ -d "$CN_QUICKSTART/artifacts" ] && cp -r "$CN_QUICKSTART/artifacts" "$TARGET_DIR/" 2>/dev/null || true
    [ -d "$CN_QUICKSTART/.daml" ] && cp -r "$CN_QUICKSTART/.daml" "$TARGET_DIR/" 2>/dev/null || true

    # Copy daml.yaml
    [ -f "$CN_QUICKSTART/daml.yaml" ] && cp "$CN_QUICKSTART/daml.yaml" "$TARGET_DIR/daml/" 2>/dev/null || true

    echo -e "${GREEN}  ✅ DAML contracts migrated${NC}"
    echo "     - Contracts: $(find $TARGET_DIR/daml -name "*.daml" | wc -l) files"
else
    echo -e "${YELLOW}  ⚠️ No DAML contracts found in cn-quickstart${NC}"
fi

# ============================================================================
# Backend Migration
# ============================================================================
echo -e "\n${BLUE}Step 2: Migrating Backend Code...${NC}"
BACKEND_SOURCE="/root/cn-quickstart/quickstart/backend"
if [ -d "$BACKEND_SOURCE" ]; then
    mkdir -p "$TARGET_DIR/backend/src"

    # Copy source code
    [ -d "$BACKEND_SOURCE/src" ] && cp -r "$BACKEND_SOURCE/src/"* "$TARGET_DIR/backend/src/" 2>/dev/null || true

    # Copy build files
    [ -f "$BACKEND_SOURCE/build.gradle.kts" ] && cp "$BACKEND_SOURCE/build.gradle.kts" "$TARGET_DIR/backend/" 2>/dev/null || true
    [ -f "$BACKEND_SOURCE/settings.gradle.kts" ] && cp "$BACKEND_SOURCE/settings.gradle.kts" "$TARGET_DIR/backend/" 2>/dev/null || true

    # Update package names
    find "$TARGET_DIR/backend" -type f -name "*.java" -o -name "*.kt" | while read file; do
        sed -i 's/com\.digitalasset\.quickstart/com.clearportx/g' "$file" 2>/dev/null || true
        sed -i 's/clearportx_amm/clearportx_amm_production/g' "$file" 2>/dev/null || true
    done

    echo -e "${GREEN}  ✅ Backend code migrated${NC}"
    echo "     - Java files: $(find $TARGET_DIR/backend -name "*.java" | wc -l)"
else
    echo -e "${YELLOW}  ⚠️ No backend found in cn-quickstart${NC}"
fi

# ============================================================================
# Frontend Migration from canton-website
# ============================================================================
echo -e "\n${BLUE}Step 3: Migrating Frontend from canton-website...${NC}"
if [ -d "$CANTON_WEBSITE" ]; then
    echo -e "${GREEN}  ✅ Found canton-website at $CANTON_WEBSITE${NC}"

    mkdir -p "$TARGET_DIR/frontend"

    # Copy entire React app structure
    echo "  - Copying React application structure..."
    [ -d "$CANTON_WEBSITE/src" ] && cp -r "$CANTON_WEBSITE/src" "$TARGET_DIR/frontend/" 2>/dev/null || true
    [ -d "$CANTON_WEBSITE/public" ] && cp -r "$CANTON_WEBSITE/public" "$TARGET_DIR/frontend/" 2>/dev/null || true

    # Copy configuration files
    echo "  - Copying configuration files..."
    [ -f "$CANTON_WEBSITE/package.json" ] && cp "$CANTON_WEBSITE/package.json" "$TARGET_DIR/frontend/" 2>/dev/null || true
    [ -f "$CANTON_WEBSITE/package-lock.json" ] && cp "$CANTON_WEBSITE/package-lock.json" "$TARGET_DIR/frontend/" 2>/dev/null || true
    [ -f "$CANTON_WEBSITE/tsconfig.json" ] && cp "$CANTON_WEBSITE/tsconfig.json" "$TARGET_DIR/frontend/" 2>/dev/null || true
    [ -f "$CANTON_WEBSITE/vite.config.ts" ] && cp "$CANTON_WEBSITE/vite.config.ts" "$TARGET_DIR/frontend/" 2>/dev/null || true
    [ -f "$CANTON_WEBSITE/index.html" ] && cp "$CANTON_WEBSITE/index.html" "$TARGET_DIR/frontend/" 2>/dev/null || true
    [ -f "$CANTON_WEBSITE/.env.local" ] && cp "$CANTON_WEBSITE/.env.local" "$TARGET_DIR/frontend/.env" 2>/dev/null || true

    # Copy additional config files
    [ -f "$CANTON_WEBSITE/postcss.config.js" ] && cp "$CANTON_WEBSITE/postcss.config.js" "$TARGET_DIR/frontend/" 2>/dev/null || true
    [ -f "$CANTON_WEBSITE/tailwind.config.js" ] && cp "$CANTON_WEBSITE/tailwind.config.js" "$TARGET_DIR/frontend/" 2>/dev/null || true
    [ -f "$CANTON_WEBSITE/.eslintrc.json" ] && cp "$CANTON_WEBSITE/.eslintrc.json" "$TARGET_DIR/frontend/" 2>/dev/null || true

    echo -e "${GREEN}  ✅ Canton-website frontend migrated${NC}"
    echo "     - Components: $(find $TARGET_DIR/frontend/src -name "*.tsx" 2>/dev/null | wc -l) TSX files"
    echo "     - Services: $(find $TARGET_DIR/frontend/src -name "*.ts" 2>/dev/null | wc -l) TS files"
    echo "     - Styles: $(find $TARGET_DIR/frontend/src -name "*.css" -o -name "*.scss" 2>/dev/null | wc -l) style files"
else
    echo -e "${RED}  ❌ Canton-website not found at $CANTON_WEBSITE${NC}"
fi

# ============================================================================
# Copy Important Documents
# ============================================================================
echo -e "\n${BLUE}Step 4: Copying Important Documents...${NC}"

# Copy from cn-quickstart/clearportx
if [ -d "$CN_QUICKSTART" ]; then
    docs_to_copy=(
        "OAUTH_INTEGRATION_COMPLETE.md"
        "DEVNET_ACTION_PLAN.md"
        "COMPLETE_LIQUIDITY_GUIDE.md"
        "InitDevNetComplete.daml"
        "TestDirectPoolSwap.daml"
        "DirectMintTokens.daml"
    )

    for doc in "${docs_to_copy[@]}"; do
        if [ -f "$CN_QUICKSTART/$doc" ]; then
            cp "$CN_QUICKSTART/$doc" "$TARGET_DIR/docs/imported/" 2>/dev/null || mkdir -p "$TARGET_DIR/docs/imported" && cp "$CN_QUICKSTART/$doc" "$TARGET_DIR/docs/imported/" 2>/dev/null || true
            echo "  - Copied: $doc"
        fi
    done
fi

echo -e "${GREEN}  ✅ Documents copied${NC}"

# ============================================================================
# Configuration Files
# ============================================================================
echo -e "\n${BLUE}Step 5: Updating Configuration Files...${NC}"

# Create .env if it doesn't exist
if [ ! -f "$TARGET_DIR/.env" ]; then
    cat > "$TARGET_DIR/.env" << 'EOF'
# Canton Network
LEDGER_HOST=localhost
LEDGER_PORT=3901
PARTY_ID=app_provider_quickstart-root-1::12201300e204e8a38492e7df0ca7cf67ec3fe3355407903a72323fd72da9f368a45d

# DevNet Party (when connected)
DEVNET_PARTY_ID=ClearportX-DEX-1::122043801dccdfd8c892fa46ebc1dafc901f7992218886840830aeef1cf7eacedd09

# OAuth Configuration
OAUTH_ENABLED=true
OAUTH_BASE_URL=http://localhost:8082
OAUTH_REALM=AppProvider
OAUTH_CLIENT_ID=app-provider-unsafe
OAUTH_REDIRECT_URI=http://localhost:5173/auth/callback

# Backend
SERVER_PORT=8080
SPRING_PROFILES_ACTIVE=development
DB_HOST=localhost
DB_PORT=5432
DB_NAME=clearportx
DB_USER=clearportx
DB_PASSWORD=clearportx123

# Frontend
VITE_API_URL=http://localhost:8080
VITE_AUTH_ENABLED=true
VITE_OAUTH_BASE_URL=http://localhost:8082

# Docker
COMPOSE_PROJECT_NAME=clearportx
EOF
    echo -e "${GREEN}  ✅ Created .env file${NC}"
fi

# ============================================================================
# Create Migration Summary
# ============================================================================
echo -e "\n${BLUE}Step 6: Creating Migration Summary...${NC}"

cat > "$TARGET_DIR/MIGRATION_SUMMARY.md" << EOF
# Migration Summary - $(date)

## What Was Migrated

### From cn-quickstart ($CN_QUICKSTART):
- ✅ DAML contracts ($(find $TARGET_DIR/daml -name "*.daml" 2>/dev/null | wc -l) files)
- ✅ Backend code ($(find $TARGET_DIR/backend -name "*.java" 2>/dev/null | wc -l) Java files)
- ✅ DAR artifacts
- ✅ Configuration files

### From canton-website ($CANTON_WEBSITE):
- ✅ React frontend application
- ✅ Components ($(find $TARGET_DIR/frontend/src/components -name "*.tsx" 2>/dev/null | wc -l) files)
- ✅ Services ($(find $TARGET_DIR/frontend/src/services -name "*.ts" 2>/dev/null | wc -l) files)
- ✅ Package configuration

## Next Steps

1. Install dependencies:
   \`\`\`bash
   cd $TARGET_DIR
   make install
   \`\`\`

2. Build everything:
   \`\`\`bash
   make build
   \`\`\`

3. Start services:
   \`\`\`bash
   docker-compose up -d
   \`\`\`

4. Initialize pools:
   \`\`\`bash
   make init-local
   \`\`\`

## Important Files

- Session handover: SESSION_HANDOVER.md
- Work history: COMPLETE_WORK_HISTORY.md
- Architecture: docs/ARCHITECTURE.md
- API docs: docs/API.md

## Backup Location
$BACKUP_DIR
EOF

echo -e "${GREEN}  ✅ Migration summary created${NC}"

# ============================================================================
# Final Validation
# ============================================================================
echo -e "\n${BLUE}🔍 Validating Migration...${NC}"

errors=0
warnings=0

# Check critical files
critical_files=(
    "daml/AMM/Pool.daml"
    "daml/Token/Token.daml"
    "backend/build.gradle.kts"
    "frontend/package.json"
    "docker-compose.yml"
    "Makefile"
)

for file in "${critical_files[@]}"; do
    if [ -f "$TARGET_DIR/$file" ]; then
        echo -e "${GREEN}  ✅ $file${NC}"
    else
        echo -e "${YELLOW}  ⚠️ Missing: $file${NC}"
        ((warnings++))
    fi
done

# ============================================================================
# Summary
# ============================================================================
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                   Migration Complete!                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
    echo -e "${GREEN}✅ Perfect migration! All files transferred successfully.${NC}"
else
    echo -e "${YELLOW}⚠️ Migration completed with $warnings warnings.${NC}"
fi

echo ""
echo -e "${CYAN}Repository ready at: $TARGET_DIR${NC}"
echo ""
echo -e "${CYAN}Quick Start:${NC}"
echo "  cd $TARGET_DIR"
echo "  ./verify-setup.sh    # Check setup"
echo "  make build           # Build everything"
echo "  docker-compose up -d # Start services"
echo "  make init-local      # Initialize pools"
echo ""
echo -e "${CYAN}Access Points:${NC}"
echo "  Frontend: http://localhost:5173"
echo "  Backend:  http://localhost:8080"
echo "  Swagger:  http://localhost:8080/swagger-ui.html"
echo ""
echo -e "${GREEN}📚 Documentation:${NC}"
echo "  - SESSION_HANDOVER.md - Next session guide"
echo "  - COMPLETE_WORK_HISTORY.md - Full project history"
echo "  - MIGRATION_SUMMARY.md - What was migrated"
echo ""
echo -e "${YELLOW}Remember to:${NC}"
echo "  1. Review the .env file"
echo "  2. Update database credentials"
echo "  3. Configure OAuth settings"
echo "  4. Check Canton participant connection"
echo ""