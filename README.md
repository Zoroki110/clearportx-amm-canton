# ClearportX AMM DEX on Canton Network

A production-ready Automated Market Maker (AMM) Decentralized Exchange built on the Canton Network, featuring atomic swaps, liquidity pools, and LP token rewards.

## Overview

ClearportX is a fully decentralized AMM that enables:
- Constant Product Market Maker (x*y=k) for token swaps
- Atomic swap execution with guaranteed consistency
- Liquidity provision with LP token rewards
- Protocol fee collection (0.3% swap fee)
- Multi-pool support with automatic price discovery
- Real-time metrics and monitoring

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Frontend (React + TypeScript)            │
│  - Swap Interface  - Liquidity Pools  - Portfolio View      │
└────────────────────────┬────────────────────────────────────┘
                         │ REST API
┌────────────────────────▼────────────────────────────────────┐
│              Backend (Spring Boot + Kotlin)                  │
│  - Pool Controller  - Swap Controller  - OAuth/JWT Auth     │
└────────────────────────┬────────────────────────────────────┘
                         │ Canton Ledger API
┌────────────────────────▼────────────────────────────────────┐
│                  Canton Network Participant                  │
│  - Smart Contracts (DAML)  - Event Streaming                │
└─────────────────────────────────────────────────────────────┘
```

## Features

### Core AMM Functionality
- **Atomic Swaps**: Guaranteed execution or rollback with DAML contracts
- **Liquidity Pools**: Create and manage token pairs with constant product formula
- **LP Tokens**: Proportional ownership tokens for liquidity providers
- **Fee Distribution**: 0.3% trading fee distributed to LP token holders
- **Price Oracle**: Real-time spot price calculation based on reserves

### Security
- OAuth 2.0 / JWT authentication
- Party-based authorization in DAML
- Input validation and sanitization
- Rate limiting and CORS protection
- Audit logging for all transactions

### Monitoring
- Prometheus metrics export
- Grafana dashboards
- Real-time transaction tracking
- Pool analytics and volume tracking

## Quick Start

### Prerequisites

- **Canton SDK**: 3.3.0 or higher
- **DAML SDK**: 3.3.0 or higher
- **Java**: 17 or higher
- **Node.js**: 18 or higher
- **Docker**: 20.10 or higher (optional, for containerized deployment)
- **Gradle**: 8.0 or higher

### Local Development Setup

1. **Clone and Setup**
```bash
git clone <repository-url>
cd clearportx-amm-canton
```

2. **Build DAML Contracts**
```bash
cd daml
daml build
# Output: .daml/dist/clearportx-amm-1.0.0.dar
```

3. **Start Canton Node** (Local Development)
```bash
docker-compose up -d canton
# Or use existing Canton participant
```

4. **Deploy DAR to Canton**
```bash
./infrastructure/scripts/deploy-local.sh
```

5. **Start Backend Service**
```bash
cd backend
./gradlew bootRun
# Backend runs on http://localhost:8080
```

6. **Start Frontend**
```bash
cd frontend
npm install
npm run dev
# Frontend runs on http://localhost:5173
```

7. **Initialize Pools** (Optional)
```bash
./infrastructure/scripts/init-pools.sh
```

### DevNet Deployment

For Canton DevNet deployment:

```bash
# Configure DevNet credentials
cp config/devnet.env.example config/devnet.env
# Edit config/devnet.env with your credentials

# Deploy to DevNet
./infrastructure/scripts/deploy-devnet.sh
```

See [DEPLOYMENT.md](docs/DEPLOYMENT.md) for detailed deployment instructions.

## Configuration

### Environment Variables

Create `.env` file in project root:

```bash
# Canton Network
CANTON_PARTICIPANT_HOST=localhost
CANTON_PARTICIPANT_PORT=3901
CANTON_ADMIN_PORT=3902
CANTON_LEDGER_API_PORT=3901

# Backend
BACKEND_PORT=8080
JWT_SECRET=your-secret-key-here
OAUTH_CLIENT_ID=your-client-id
OAUTH_CLIENT_SECRET=your-client-secret

# Database (optional - uses in-memory H2 by default)
DATABASE_URL=jdbc:postgresql://localhost:5432/clearportx
DATABASE_USER=clearportx
DATABASE_PASSWORD=change-me

# Frontend
VITE_API_URL=http://localhost:8080
VITE_OAUTH_CLIENT_ID=your-client-id
```

### Canton Configuration

Edit `infrastructure/canton/canton.conf` for your Canton node setup.

## API Documentation

### Swagger UI
Once backend is running, access API documentation at:
```
http://localhost:8080/swagger-ui.html
```

### Key Endpoints

**Pools**
- `GET /api/v1/pools` - List all pools
- `GET /api/v1/pools/{id}` - Get pool details
- `POST /api/v1/pools` - Create new pool
- `POST /api/v1/pools/{id}/liquidity` - Add liquidity

**Swaps**
- `POST /api/v1/swaps` - Execute swap
- `GET /api/v1/swaps/{id}` - Get swap status
- `GET /api/v1/swaps/history` - Get swap history

**Analytics**
- `GET /api/v1/analytics/volume` - Get 24h volume
- `GET /api/v1/analytics/tvl` - Get total value locked

See [API.md](docs/API.md) for complete API reference.

## Testing

### DAML Tests
```bash
cd daml
daml test
```

### Backend Tests
```bash
cd backend
./gradlew test
./gradlew integrationTest
```

### Frontend Tests
```bash
cd frontend
npm test
npm run test:e2e
```

### End-to-End Tests
```bash
./test/e2e/run-tests.sh
```

## Project Structure

```
clearportx-amm-canton/
├── daml/                    # DAML smart contracts
│   ├── AMM/                 # Core AMM contracts
│   ├── Token/               # Token standard
│   ├── LPToken/             # LP token implementation
│   ├── Protocol/            # Fee collection
│   └── Init/                # Initialization scripts
├── backend/                 # Spring Boot backend
│   └── src/main/
│       ├── java/            # Java/Kotlin source
│       └── resources/       # Configuration files
├── frontend/                # React frontend
│   └── src/
│       ├── components/      # React components
│       ├── services/        # API clients
│       └── hooks/           # Custom hooks
├── infrastructure/          # Infrastructure as code
│   ├── canton/              # Canton configurations
│   ├── docker/              # Dockerfiles
│   ├── kubernetes/          # K8s manifests
│   └── scripts/             # Deployment scripts
├── devops/                  # DevOps configurations
│   ├── .github/workflows/   # CI/CD pipelines
│   └── monitoring/          # Monitoring configs
├── docs/                    # Documentation
└── test/                    # Test suites
```

## Monitoring and Metrics

### Prometheus Metrics

Backend exposes metrics at `/actuator/prometheus`:
- `clearportx_swaps_total` - Total number of swaps
- `clearportx_swap_volume` - Total swap volume
- `clearportx_pool_tvl` - Total value locked per pool
- `clearportx_liquidity_operations` - Liquidity add/remove operations

### Grafana Dashboard

Import dashboard from `devops/monitoring/grafana-dashboard.json`

Key metrics:
- 24h Trading Volume
- Total Value Locked (TVL)
- Swap Success Rate
- Average Swap Time
- Pool Utilization

## Production Deployment

### Canton MainNet

1. Obtain Canton MainNet participant credentials
2. Configure `config/mainnet.env`
3. Deploy:
```bash
./infrastructure/scripts/deploy-mainnet.sh
```

### Kubernetes Deployment

```bash
kubectl apply -f infrastructure/kubernetes/
```

### Docker Compose (All-in-One)

```bash
docker-compose up -d
```

## Security Considerations

- All transactions require valid JWT authentication
- DAML contracts enforce party authorization
- Rate limiting: 100 requests/minute per IP
- CORS configured for known origins only
- Input validation on all endpoints
- Secrets stored in environment variables (never committed)

## Troubleshooting

### Common Issues

**1. Canton Connection Failed**
```bash
# Check Canton is running
curl http://localhost:3902/health

# Verify participant ID
./infrastructure/scripts/check-participant.sh
```

**2. DAR Upload Failed**
```bash
# Verify DAR file exists
ls -la daml/.daml/dist/*.dar

# Check Canton admin API
./infrastructure/scripts/verify-dar.sh
```

**3. Backend Can't Connect to Canton**
- Verify `CANTON_PARTICIPANT_HOST` and `CANTON_LEDGER_API_PORT`
- Check firewall rules
- Ensure participant is synchronized

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for more details.

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## Documentation

- [Architecture Guide](docs/ARCHITECTURE.md)
- [API Reference](docs/API.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
- [Canton Integration](docs/CANTON_INTEGRATION.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## License

MIT License - see LICENSE file for details

## Support

- Documentation: [docs/](docs/)
- Issues: GitHub Issues
- Canton Network: https://www.canton.network

## Roadmap

- [ ] Multi-hop routing for optimal swap paths
- [ ] Concentrated liquidity (Uniswap v3 style)
- [ ] Limit orders
- [ ] Governance token and DAO
- [ ] Cross-chain bridge integration
- [ ] Mobile app (React Native)

## Acknowledgments

Built on:
- [Canton Network](https://www.canton.network) - Privacy-enabled blockchain
- [DAML](https://daml.com) - Smart contract language
- [Spring Boot](https://spring.io/projects/spring-boot) - Backend framework
- [React](https://react.dev) - Frontend framework
