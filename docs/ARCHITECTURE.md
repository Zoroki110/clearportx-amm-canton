# ClearportX AMM Architecture

## System Overview

ClearportX is a decentralized AMM (Automated Market Maker) DEX built on the Canton Network using DAML smart contracts. The system enables trustless token swaps, liquidity provision, and LP token rewards.

## Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ React Web UI │  │ Mobile App   │  │  API Docs    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────┬───────────────────────────────────────┘
                      │ HTTPS / WebSocket
┌─────────────────────▼───────────────────────────────────────┐
│                     Application Layer                        │
│  ┌──────────────────────────────────────────────────────┐  │
│  │        Spring Boot Backend (Kotlin/Java)              │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐ │  │
│  │  │ Pool    │  │  Swap   │  │Liquidity│  │Analytics│ │  │
│  │  │Controller  │Controller│  │Controller  │Controller│ │  │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘ │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐              │  │
│  │  │ Ledger  │  │ Token   │  │ Metrics │              │  │
│  │  │ Service │  │ Service │  │ Service │              │  │
│  │  └─────────┘  └─────────┘  └─────────┘              │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────┬───────────────────────────────────────┘
                      │ gRPC / Ledger API
┌─────────────────────▼───────────────────────────────────────┐
│                   Canton Network Layer                       │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           Canton Participant Node                     │  │
│  │  - Ledger API (gRPC)                                  │  │
│  │  - Admin API                                          │  │
│  │  - Event Streaming                                    │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────┬───────────────────────────────────────┘
                      │ Canton Protocol
┌─────────────────────▼───────────────────────────────────────┐
│                 Smart Contract Layer (DAML)                  │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐       │
│  │  Pool   │  │  Token  │  │ LPToken │  │Protocol │       │
│  │Contract │  │Contract │  │Contract │  │  Fees   │       │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘       │
└─────────────────────────────────────────────────────────────┘
```

## Smart Contract Design (DAML)

### Core Contracts

#### 1. **Pool Contract** (`AMM/Pool.daml`)
The main liquidity pool contract implementing constant product market maker (x*y=k).

**Fields:**
- `poolOperator`: Admin party
- `poolParty`: Pool owner (holds reserves)
- `lpIssuer`: LP token issuer
- `symbolA`, `symbolB`: Token pair
- `reserveA`, `reserveB`: Current reserves
- `totalLPSupply`: Total LP tokens minted
- `feeBps`: Swap fee (basis points)
- `protocolFeeReceiver`: Protocol treasury

**Key Choices:**
- `AddLiquidity`: Deposit tokens, receive LP tokens
- `RemoveLiquidity`: Burn LP tokens, withdraw tokens
- `AtomicSwap`: Execute swap in single transaction
- `ArchiveAndUpdateReserves`: Update reserves after swap

**Formulas:**
```
LP Tokens (first deposit) = sqrt(amountA * amountB)
LP Tokens (subsequent)    = min(amountA * supply / reserveA,
                                amountB * supply / reserveB)

Swap Output = (inputAmount * feeMultiplier * outputReserve) /
              (inputReserve + inputAmount * feeMultiplier)

where feeMultiplier = (10000 - feeBps) / 10000
```

#### 2. **Token Contract** (`Token/Token.daml`)
Standard fungible token with issuer-controlled transfers.

**Design Choice:** Issuer is sole signatory to enable atomic swaps without multi-party consent.

**Choices:**
- `Transfer`: Transfer tokens to recipient
- `TransferSplit`: Split and transfer (for fee extraction)
- `Merge`: Consolidate token fragments
- `Credit`: Mint new tokens (issuer only)

#### 3. **LPToken Contract** (`LPToken/LPToken.daml`)
Liquidity provider tokens representing pool ownership.

**Fields:**
- `issuer`: LP token issuer (lpIssuer)
- `owner`: LP token holder
- `poolId`: Associated pool
- `amount`: LP token quantity

**Choices:**
- `Transfer`: Transfer LP tokens
- `Burn`: Burn LP tokens (for liquidity removal)

#### 4. **PoolAnnouncement Contract** (`AMM/PoolAnnouncement.daml`)
Discovery mechanism for pools (DAML 3.x removed contract keys).

**Purpose:** Allows querying pools by symbol pair without contract keys.

### Contract Interactions

#### Swap Flow
```
1. User has Token A, wants Token B
2. User calls Pool.AtomicSwap with:
   - traderInputTokenCid (Token A contract ID)
   - inputAmount
   - minOutput (slippage protection)

3. Pool contract:
   a. Validates reserves and limits
   b. Calculates output using x*y=k formula
   c. Extracts protocol fee (25% of total fee)
   d. Transfers input token to pool
   e. Transfers output token to user
   f. Updates reserves
   g. Archives old pool, creates new with updated reserves

4. Returns:
   - New token CID for user (Token B)
   - New pool CID with updated reserves
```

#### Add Liquidity Flow
```
1. User has Token A and Token B
2. User calls Pool.AddLiquidity with:
   - tokenACid, tokenBCid
   - amountA, amountB
   - minLPTokens (slippage protection)

3. Pool contract:
   a. Validates token symbols and issuers
   b. Calculates LP tokens to mint
   c. Transfers tokens from user to pool
   d. Merges with existing pool reserves
   e. Mints LP tokens for user
   f. Updates reserves and LP supply

4. Returns:
   - LP token CID for user
   - New pool CID with updated state
```

#### Remove Liquidity Flow
```
1. User has LP tokens
2. User calls Pool.RemoveLiquidity with:
   - lpTokenCid
   - lpTokenAmount
   - minAmountA, minAmountB (slippage protection)

3. Pool contract:
   a. Calculates proportional token amounts
   b. Burns LP tokens
   c. Transfers tokens from pool to user
   d. Updates reserves and LP supply

4. Returns:
   - Token A CID for user
   - Token B CID for user
   - New pool CID with updated state
```

## Backend Architecture (Spring Boot)

### Layer Structure

```
Controllers (REST API)
    ↓
Services (Business Logic)
    ↓
LedgerService (Canton Integration)
    ↓
Canton Ledger API (gRPC)
```

### Key Services

#### **LedgerService**
Interfaces with Canton Ledger API via gRPC.

**Methods:**
- `createPool()`: Submit Pool contract
- `executeSwap()`: Submit AtomicSwap choice
- `addLiquidity()`: Submit AddLiquidity choice
- `queryPools()`: Query active pools
- `subscribeToEvents()`: Stream ledger events

#### **TokenService**
Manages token metadata and balances.

**Methods:**
- `getTokenBalance(party, symbol)`
- `mintTokens(issuer, owner, symbol, amount)`
- `getTokenMetadata(symbol)`

#### **MetricsService**
Collects and exports Prometheus metrics.

**Metrics:**
- `clearportx_swaps_total`: Counter
- `clearportx_swap_volume`: Gauge
- `clearportx_pool_tvl`: Gauge
- `clearportx_liquidity_operations`: Counter

### Security

#### Authentication Flow
```
1. User authenticates via OAuth 2.0 (Canton Auth or custom)
2. Backend receives JWT token
3. JWT validated against issuer
4. User party ID extracted from JWT claims
5. Canton operations performed on behalf of user party
```

#### Authorization
- All Canton operations require valid party
- Backend validates user owns contracts before exercising choices
- Rate limiting: 100 requests/minute per IP
- CORS: Whitelist known origins only

## Frontend Architecture (React)

### Component Structure

```
App
├── SwapInterface
│   ├── TokenSelector
│   ├── AmountInput
│   └── SwapButton
├── LiquidityPool
│   ├── PoolSelector
│   ├── LiquidityForm
│   └── LPTokenDisplay
└── PoolList
    ├── PoolCard
    └── PoolChart
```

### State Management (Zustand)

```typescript
interface AppState {
  user: User | null;
  pools: Pool[];
  selectedPool: Pool | null;
  tokenBalances: Record<string, number>;
}
```

### API Integration

```typescript
// services/cantonApi.ts
export const cantonApi = {
  getPools: () => axios.get('/api/v1/pools'),
  executeSwap: (swap) => axios.post('/api/v1/swaps', swap),
  addLiquidity: (liquidity) => axios.post('/api/v1/liquidity', liquidity),
};
```

## Deployment Architecture

### Local Development
```
Docker Compose:
- Canton Node (port 3901, 3902)
- PostgreSQL (port 5432)
- Backend (port 8080)
- Frontend (port 5173)
- Prometheus (port 9091)
- Grafana (port 3000)
```

### Production (Kubernetes)
```
Namespace: clearportx-prod
├── Deployment: clearportx-backend (3 replicas)
├── Deployment: clearportx-frontend (2 replicas)
├── StatefulSet: postgres (1 replica)
├── Service: backend-svc (ClusterIP)
├── Service: frontend-svc (ClusterIP)
├── Ingress: clearportx-ingress (HTTPS)
└── ConfigMap: app-config
```

## Data Flow

### Swap Execution
```
1. Frontend: User clicks "Swap"
   POST /api/v1/swaps

2. Backend: SwapController receives request
   → Validates input
   → Authenticates user

3. Backend: LedgerService submits to Canton
   → Fetches pool contract
   → Exercises Pool.AtomicSwap choice
   → Waits for completion

4. Canton: Executes DAML contract
   → Validates reserves
   → Calculates output
   → Transfers tokens
   → Updates pool

5. Backend: Returns result to frontend
   → Swap confirmed
   → New balances

6. Frontend: Updates UI
   → Shows success
   → Refreshes balances
```

## Monitoring & Observability

### Metrics (Prometheus)
- Application metrics (JVM, HTTP)
- Business metrics (swaps, volume, TVL)
- Canton metrics (transactions, contracts)

### Logging
- Structured JSON logging (Logback)
- Log levels: DEBUG, INFO, WARN, ERROR
- Correlation IDs for request tracing

### Dashboards (Grafana)
- Pool analytics (volume, TVL, price)
- System health (CPU, memory, latency)
- User activity (swaps, liquidity operations)

## Security Considerations

### Smart Contract Security
- Input validation on all choices
- Slippage protection (minOutput, minLPTokens)
- Reserve consistency checks
- Protocol fee extraction before swaps

### Backend Security
- JWT authentication
- Rate limiting (100 req/min)
- CORS whitelist
- Input sanitization
- SQL injection prevention (JPA)

### Infrastructure Security
- HTTPS only in production
- Secrets in environment variables
- Database encryption at rest
- Regular security audits

## Scalability

### Horizontal Scaling
- Backend: Stateless, scale to N replicas
- Frontend: Static files, CDN
- Database: Read replicas for queries

### Performance Optimizations
- Redis caching for pool data
- WebSocket for real-time updates
- Database indexing on queries
- Connection pooling (Canton gRPC)

## Future Enhancements

1. **Multi-hop Routing**: Optimal swap paths across multiple pools
2. **Concentrated Liquidity**: Uniswap v3 style range orders
3. **Limit Orders**: Off-chain matching, on-chain settlement
4. **Governance**: DAO for protocol upgrades
5. **Analytics**: Advanced charting and historical data
6. **Mobile App**: React Native for iOS/Android

## References

- [Canton Documentation](https://docs.canton.network)
- [DAML Documentation](https://docs.daml.com)
- [Uniswap V2 Whitepaper](https://uniswap.org/whitepaper.pdf)
- [Constant Product Market Maker](https://docs.uniswap.org/protocol/V2/concepts/protocol-overview/how-uniswap-works)
