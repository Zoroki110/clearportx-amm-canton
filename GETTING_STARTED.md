# Getting Started with ClearportX AMM

## Quick Start (5 minutes)

### 1. Prerequisites Check

Run the verification script:
```bash
cd /root/clearportx-amm-canton
./verify-setup.sh
```

Required:
- DAML SDK 3.3.0+
- Java 17+
- Node.js 18+
- Docker 20.10+ (optional)

### 2. Initial Setup

```bash
# Copy environment template
cp config/.env.example .env

# Edit configuration (set your Canton host, ports, etc.)
nano .env
```

### 3. Build Everything

```bash
# Build all components (DAML, backend, frontend)
make build
```

This will:
- Compile DAML contracts to DAR file
- Build backend JAR
- Build frontend static files

### 4. Start Local Development

#### Option A: Docker Compose (Recommended)
```bash
# Start all services (Canton, backend, frontend, monitoring)
docker-compose up -d

# Check logs
docker-compose logs -f
```

Services will be available at:
- Frontend: http://localhost:5173
- Backend API: http://localhost:8080
- Swagger UI: http://localhost:8080/swagger-ui.html
- Grafana: http://localhost:3000
- Prometheus: http://localhost:9091

#### Option B: Manual Start
```bash
# Terminal 1: Start Canton (if not using Docker)
cd infrastructure/canton
canton daemon -c canton.conf

# Terminal 2: Deploy DAR and initialize
./infrastructure/scripts/deploy-local.sh
./infrastructure/scripts/init-pools.sh

# Terminal 3: Start backend
cd backend
./gradlew bootRun

# Terminal 4: Start frontend
cd frontend
npm run dev
```

### 5. Verify Deployment

```bash
# Check services health
make health

# Or manually
curl http://localhost:8080/actuator/health
curl http://localhost:8080/api/v1/pools
```

## Next Steps

### Test a Swap

Using the frontend:
1. Open http://localhost:5173
2. Select tokens (e.g., ETH → USDC)
3. Enter amount
4. Click "Swap"

Using the API:
```bash
curl -X POST http://localhost:8080/api/v1/swaps \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "poolId": "ETH-USDC",
    "inputSymbol": "ETH",
    "outputSymbol": "USDC",
    "inputAmount": 1.0,
    "minOutput": 2900,
    "slippageTolerance": 0.5
  }'
```

### Add Liquidity

```bash
curl -X POST http://localhost:8080/api/v1/pools/ETH-USDC/liquidity \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "amountA": 10.0,
    "amountB": 30000.0,
    "minLPTokens": 5000
  }'
```

### View Metrics

Open Grafana:
1. Navigate to http://localhost:3000
2. Login (admin/admin)
3. Go to Dashboards → ClearportX AMM
4. View real-time metrics

## Development Workflow

### Making Changes

1. **DAML Contracts:**
   ```bash
   cd daml
   # Edit contracts
   nano AMM/Pool.daml

   # Test
   daml test

   # Build
   daml build

   # Deploy
   ../infrastructure/scripts/deploy-local.sh
   ```

2. **Backend:**
   ```bash
   cd backend
   # Edit code
   nano src/main/java/com/clearportx/controller/SwapController.java

   # Test
   ./gradlew test

   # Run
   ./gradlew bootRun
   ```

3. **Frontend:**
   ```bash
   cd frontend
   # Edit components
   nano src/components/SwapInterface.tsx

   # Test
   npm test

   # Dev server (hot reload)
   npm run dev
   ```

### Running Tests

```bash
# All tests
make test

# DAML only
cd daml && daml test

# Backend only
cd backend && ./gradlew test

# Frontend only
cd frontend && npm test

# End-to-end
./test/e2e/run-tests.sh
```

### Debugging

Enable debug logging:
```yaml
# backend/src/main/resources/application.yml
logging:
  level:
    com.clearportx: DEBUG
```

View logs:
```bash
# Docker
docker-compose logs -f backend

# Local
tail -f logs/clearportx-amm.log
```

## Deployment

### Deploy to Canton DevNet

1. Configure DevNet credentials:
   ```bash
   cp config/devnet.env.example config/devnet.env
   nano config/devnet.env
   ```

2. Deploy:
   ```bash
   make deploy-devnet
   ```

3. Initialize pools:
   ```bash
   cd daml
   daml script \
     --dar .daml/dist/clearportx-amm-1.0.0.dar \
     --script-name Init.DevNetInit:initialize \
     --ledger-host $CANTON_DEVNET_HOST \
     --ledger-port $CANTON_DEVNET_PORT \
     --access-token-file $CANTON_DEVNET_TOKEN_FILE
   ```

### Deploy to Production

See [DEPLOYMENT.md](docs/DEPLOYMENT.md) for complete production deployment guide.

## Common Tasks

### Create a New Pool

```daml
-- daml/MyPool.daml
module MyPool where

import Daml.Script
import qualified AMM.Pool as P
import DA.Time (days)

createNewPool : Script ()
createNewPool = script do
  poolOperator <- allocateParty "PoolOperator"
  poolParty <- allocateParty "PoolParty"
  lpIssuer <- allocateParty "LPIssuer"

  pool <- submit poolOperator do
    createCmd P.Pool with
      poolOperator = poolOperator
      poolParty = poolParty
      lpIssuer = lpIssuer
      symbolA = "BTC"
      symbolB = "ETH"
      -- ... other fields
```

### Add Monitoring Alerts

Edit `devops/monitoring/alerts.yml`:
```yaml
groups:
  - name: clearportx
    rules:
      - alert: HighSlippage
        expr: clearportx_swap_slippage > 5
        for: 5m
        annotations:
          summary: "High slippage detected"
```

### Backup Data

```bash
# Manual backup
./infrastructure/scripts/backup.sh

# Automated (cron)
0 2 * * * /root/clearportx-amm-canton/infrastructure/scripts/backup.sh
```

## Migration from cn-quickstart

If migrating from the old cn-quickstart structure:

```bash
# Run migration script
./migrate-from-cn-quickstart.sh

# Review migration report
cat MIGRATION_REPORT.md

# Verify migration
./verify-setup.sh

# Test
make test
```

## Troubleshooting

### Issue: Canton won't start
```bash
# Check logs
docker logs clearportx-canton

# Verify config
cat infrastructure/canton/canton.conf

# Reset
docker-compose down -v
docker-compose up -d canton
```

### Issue: DAR upload fails
```bash
# Check participant
daml ledger list-parties --host localhost --port 3901

# Try manual upload
daml ledger upload-dar daml/.daml/dist/clearportx-amm-1.0.0.dar \
  --host localhost --port 3901
```

### Issue: API returns 401 Unauthorized
```bash
# Check JWT configuration
grep OAUTH .env

# Test without auth (dev only)
curl http://localhost:8080/api/v1/pools
```

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for more issues and solutions.

## Learning Resources

- [Architecture Overview](docs/ARCHITECTURE.md)
- [API Reference](docs/API.md)
- [Canton Documentation](https://docs.canton.network)
- [DAML Documentation](https://docs.daml.com)

## Getting Help

- **Documentation:** Check `docs/` directory
- **Issues:** Create GitHub issue
- **Community:** Join Discord
- **Support:** support@clearportx.com

## What's Next?

1. **Explore the codebase:**
   - Read `docs/ARCHITECTURE.md`
   - Review smart contracts in `daml/`
   - Check API endpoints in `backend/src/`

2. **Customize:**
   - Add new token pairs
   - Adjust fee parameters
   - Customize UI theme

3. **Deploy:**
   - Test on DevNet
   - Deploy to MainNet
   - Set up monitoring

4. **Contribute:**
   - Fix bugs
   - Add features
   - Improve documentation

Welcome to ClearportX! Happy building! 🚀
