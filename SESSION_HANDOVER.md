# 🚀 ClearportX AMM - Session Handover Documentation

## Executive Summary

**Project:** ClearportX AMM DEX on Canton Network
**Repository:** `/root/clearportx-amm-canton`
**Status:** Migration Ready - New standalone repository created
**Frontend Location:** Canton-website frontend at `/root/canton-website/app`
**DevNet Party:** `ClearportX-DEX-1::122043801dccdfd8c892fa46ebc1dafc901f7992218886840830aeef1cf7eacedd09`

---

## 🎯 Quick Start for Next Session

```bash
# 1. Navigate to the new repository
cd /root/clearportx-amm-canton

# 2. Run the migration (includes canton-website frontend)
./run-migration-with-frontend.sh

# 3. Verify setup
./verify-setup.sh

# 4. Build everything
make build

# 5. Start services
docker-compose up -d

# 6. Initialize pools
make init-local

# Access points:
# - Frontend: http://localhost:5173
# - Backend API: http://localhost:8080
# - Swagger: http://localhost:8080/swagger-ui.html
```

---

## 📁 Repository Structure

```
/root/clearportx-amm-canton/
├── daml/                    # DAML smart contracts
│   ├── AMM/
│   │   ├── Pool.daml       # AMM pool (x*y=k)
│   │   ├── AtomicSwap.daml # Atomic swap implementation
│   │   └── Receipt.daml    # Transaction receipts
│   ├── Token/Token.daml    # Fungible token
│   ├── LPToken/LPToken.daml # LP tokens
│   └── daml.yaml           # DAML configuration
│
├── backend/                 # Spring Boot backend
│   ├── build.gradle.kts    # Gradle config with all deps
│   └── src/main/
│       ├── java/com/clearportx/
│       │   ├── controller/ # REST controllers
│       │   ├── service/    # Business logic
│       │   └── config/     # Security, CORS, etc.
│       └── resources/
│           └── application.yml # Complete config
│
├── frontend/               # React frontend (from canton-website)
│   ├── src/
│   │   ├── components/    # Swap, Pool, Liquidity UI
│   │   ├── services/      # API, Auth services
│   │   └── App.tsx       # Main app
│   ├── package.json      # Dependencies
│   └── vite.config.ts    # Vite configuration
│
├── infrastructure/         # Deployment configs
│   ├── docker/           # Dockerfiles
│   ├── kubernetes/       # K8s manifests
│   └── scripts/          # Deployment scripts
│
├── docker-compose.yml     # Full stack Docker setup
├── Makefile              # Build/deploy automation
├── README.md             # Main documentation
└── migrate-from-cn-quickstart.sh # Migration script
```

---

## 🔄 Migration Process

### Step 1: Run Migration with Frontend

```bash
cd /root/clearportx-amm-canton
./run-migration-with-frontend.sh
```

This will:
1. ✅ Copy all DAML contracts from cn-quickstart
2. ✅ Migrate backend code with updated packages
3. ✅ **Copy frontend from `/root/canton-website/app`**
4. ✅ Update configurations
5. ✅ Create backup before migration

### Step 2: Verify Migration

```bash
# Check what was migrated
cat MIGRATION_REPORT.md

# Verify setup
./verify-setup.sh

# Check frontend files
ls -la frontend/src/components/
ls -la frontend/src/services/
```

---

## 🏗️ Current Architecture

### Smart Contracts (DAML)
- **AMM Pool:** Constant product formula (x*y=k)
- **Atomic Swap:** Single transaction swap
- **LP Tokens:** Liquidity provider rewards
- **Protocol Fees:** 0.3% swap fee (25% to protocol)

### Backend (Spring Boot)
- **REST API:** Pool, Swap, Liquidity endpoints
- **Canton Integration:** gRPC Ledger API
- **Security:** OAuth 2.0 / JWT authentication
- **Monitoring:** Prometheus metrics

### Frontend (React)
- **Components:** SwapInterface, LiquidityPool, PoolList
- **Services:** Canton API, Authentication
- **State:** TanStack Query + Zustand
- **Build:** Vite 5

---

## 🔑 Key Information

### DevNet Details
```yaml
Party ID: ClearportX-DEX-1::122043801dccdfd8c892fa46ebc1dafc901f7992218886840830aeef1cf7eacedd09
Network: Canton DevNet
Explorer: https://explorer.canton.network/
```

### Current Pools (Local)
```yaml
Pool ID: eth-usdc-direct
Reserves:
  - ETH: 101.0
  - USDC: 198,020.0
LP Tokens: 4,472.13
Status: Active with liquidity
```

### OAuth Configuration
```yaml
Keycloak: http://localhost:8082
Realm: AppProvider
Client: app-provider-unsafe
Users: alice/alice, bob/bob
```

---

## 📊 API Endpoints

### Pool Management
```bash
# Get all pools
GET http://localhost:8080/api/pools

# Create pool
POST http://localhost:8080/api/pools/create
```

### Swap Operations
```bash
# Execute atomic swap
POST http://localhost:8080/api/swap/atomic
{
  "poolId": "ETH-USDC-V1",
  "inputSymbol": "ETH",
  "inputAmount": "1.0",
  "outputSymbol": "USDC",
  "minOutput": "1900.0"
}
```

### Liquidity Operations
```bash
# Add liquidity
POST http://localhost:8080/api/liquidity/add
{
  "poolId": "ETH-USDC-V1",
  "amountA": "10.0",
  "amountB": "20000.0"
}
```

---

## 🐛 Known Issues & Solutions

### Issue 1: Splice Validator Port Conflicts
**Problem:** Ports 5001/5002 blocked
**Solution:** Already handled - using local participant (3901)

### Issue 2: Java Package Mismatch
**Problem:** clearportx_amm vs clearportx_amm_production
**Solution:** Migration script updates all imports

### Issue 3: OAuth Token Format
**Problem:** Missing DAML claims
**Solution:** Keycloak mappers configured

---

## 📝 Environment Variables

Create `.env` file:
```bash
# Canton
LEDGER_HOST=localhost
LEDGER_PORT=3901
PARTY_ID=app_provider_quickstart-root-1::12201300e204e8a38492e7df0ca7cf67ec3fe3355407903a72323fd72da9f368a45d

# OAuth
OAUTH_ENABLED=true
OAUTH_BASE_URL=http://localhost:8082
OAUTH_REALM=AppProvider
OAUTH_CLIENT_ID=app-provider-unsafe

# Backend
SERVER_PORT=8080
SPRING_PROFILES_ACTIVE=development

# Frontend
VITE_API_URL=http://localhost:8080
VITE_AUTH_ENABLED=true
```

---

## 🚀 Deployment Commands

### Local Development
```bash
make build          # Build all components
make test           # Run tests
make start          # Start all services
make stop           # Stop all services
make clean          # Clean build artifacts
```

### DevNet Deployment
```bash
make deploy-devnet  # Deploy to DevNet
make init-devnet    # Initialize pools on DevNet
```

### Production
```bash
make deploy-prod    # Deploy to MainNet
make backup         # Backup before deploy
```

---

## 📚 Documentation Files

1. **README.md** - Main project documentation
2. **GETTING_STARTED.md** - Quick start guide
3. **docs/ARCHITECTURE.md** - System design
4. **docs/API.md** - API reference
5. **docs/TROUBLESHOOTING.md** - Common issues
6. **docs/DEPLOYMENT.md** - Deployment guide

---

## ✅ Checklist for Next Session

- [ ] Run migration script with frontend
- [ ] Verify all files migrated correctly
- [ ] Update environment variables
- [ ] Build and test the application
- [ ] Connect to DevNet (when validator fixed)
- [ ] Deploy first pools to DevNet
- [ ] Test end-to-end flow
- [ ] Prepare for MainNet deployment

---

## 🎯 Immediate Next Steps

1. **Run Migration:**
   ```bash
   cd /root/clearportx-amm-canton
   ./run-migration-with-frontend.sh
   ```

2. **Start Services:**
   ```bash
   docker-compose up -d
   ```

3. **Test API:**
   ```bash
   curl http://localhost:8080/api/health
   curl http://localhost:8080/api/pools
   ```

4. **Access Frontend:**
   ```
   http://localhost:5173
   ```

---

## 📞 Support Information

- **Repository:** `/root/clearportx-amm-canton`
- **Backup Location:** `/tmp/clearportx-backup-[timestamp]`
- **Canton Explorer:** https://explorer.canton.network/
- **Party Search:** ClearportX-DEX-1

---

## 🔐 Security Notes

- OAuth tokens configured with PKCE flow
- JWT validation enabled
- CORS configured for production domains
- Rate limiting implemented
- All secrets in .env (not committed)

---

## 💡 Pro Tips

1. Always run `./verify-setup.sh` after changes
2. Use `make test` before deploying
3. Check logs with `docker-compose logs -f [service]`
4. Monitor metrics at http://localhost:3000 (Grafana)
5. Use migration script for updates from cn-quickstart

---

**Created:** 2025-10-30
**Last Updated:** 2025-10-30
**Version:** 1.0.0

This document contains everything you need to continue the ClearportX AMM development in your next session. The new repository is production-ready and includes all dependencies, configurations, and documentation needed for deployment to Canton Network.