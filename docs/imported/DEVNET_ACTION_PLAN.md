# 🚀 DEVNET PRODUCTION ACTION PLAN - ClearportX AMM DEX

## ✅ STEP 1: Verify DevNet Connection
```bash
# Check participant is running
nc -zv localhost 5001

# Get party ID on DevNet
daml ledger list-parties --host localhost --port 5001

# Save party ID
export PARTY_ID="ClearportX-DEX-1::1220..."
```

## ✅ STEP 2: Upload DAR to DevNet
```bash
# Upload production DAR
daml ledger upload-dar \
  /root/cn-quickstart/quickstart/clearportx/artifacts/clearportx-amm-production-1.0.5.dar \
  --host localhost \
  --port 5001 \
  --max-inbound-message-size 10000000

# Verify upload
daml ledger list-packages --host localhost --port 5001 | grep clearportx
```

## ✅ STEP 3: Initialize Pools on DevNet
```bash
# Create initialization script
cat > InitDevNetPools.daml << 'EOF'
module InitDevNetPools where

import Daml.Script
import qualified Token.Token as T
import qualified AMM.Pool as P
import qualified AMM.PoolAnnouncement as PA

initPools : Script ()
initPools = script do
  -- Get DevNet party
  let partyStr = "ClearportX-DEX-1::1220..."  -- UPDATE WITH ACTUAL PARTY ID

  case partyFromText partyStr of
    None -> debug "ERROR: Invalid party"
    Some clearportx -> do
      -- Create ETH/USDC pool
      poolCid <- submit clearportx do
        createCmd P.Pool with
          poolOperator = clearportx
          poolParty = clearportx
          lpIssuer = clearportx
          issuerA = clearportx
          issuerB = clearportx
          symbolA = "ETH"
          symbolB = "USDC"
          feeBps = 30
          poolId = "ETH-USDC-DEVNET"
          maxTTL = seconds 86400
          totalLPSupply = 0.0
          reserveA = 0.0
          reserveB = 0.0
          tokenACid = None
          tokenBCid = None
          protocolFeeReceiver = clearportx
          maxInBps = 1000
          maxOutBps = 1000

      -- Announce pool
      announcementCid <- submit clearportx do
        createCmd PA.PoolAnnouncement with
          announcer = clearportx
          poolId = "ETH-USDC-DEVNET"
          poolCid = poolCid
          symbolA = "ETH"
          symbolB = "USDC"

      debug "Pool created on DevNet!"
      return ()
EOF

# Build and run
daml build -o devnet-init.dar
daml script --dar devnet-init.dar \
  --script-name InitDevNetPools:initPools \
  --ledger-host localhost \
  --ledger-port 5001
```

## ✅ STEP 4: Add Initial Liquidity
```bash
# Create liquidity script
cat > AddDevNetLiquidity.daml << 'EOF'
module AddDevNetLiquidity where

import Daml.Script
import qualified Token.Token as T
import qualified AMM.Pool as P
import DA.Time

addLiquidity : Script ()
addLiquidity = script do
  let partyStr = "ClearportX-DEX-1::1220..."

  case partyFromText partyStr of
    None -> debug "ERROR: Invalid party"
    Some provider -> do
      -- Mint tokens
      ethCid <- submit provider do
        createCmd T.Token with
          issuer = provider
          owner = provider
          symbol = "ETH"
          amount = 100.0

      usdcCid <- submit provider do
        createCmd T.Token with
          issuer = provider
          owner = provider
          symbol = "USDC"
          amount = 200000.0

      -- Find pool
      pools <- query @P.Pool provider
      case pools of
        ((poolCid, pool) :: _) -> do
          -- Add liquidity
          let deadline = time (date 2026 Jan 1) 0 0 0
          (lpTokenCid, newPoolCid) <- submit provider do
            exerciseCmd poolCid P.AddLiquidity with
              provider = provider
              tokenACid = ethCid
              tokenBCid = usdcCid
              amountA = 100.0
              amountB = 200000.0
              minLPTokens = 0.0
              deadline = deadline

          debug "Liquidity added!"
          return ()
        _ -> debug "No pool found"
EOF

# Build and run
daml build -o devnet-liquidity.dar
daml script --dar devnet-liquidity.dar \
  --script-name AddDevNetLiquidity:addLiquidity \
  --ledger-host localhost \
  --ledger-port 5001
```

## ✅ STEP 5: Execute First Swap
```bash
# Create swap script
cat > ExecuteDevNetSwap.daml << 'EOF'
module ExecuteDevNetSwap where

import Daml.Script
import qualified Token.Token as T
import qualified AMM.Pool as P
import DA.Time

executeSwap : Script ()
executeSwap = script do
  let partyStr = "ClearportX-DEX-1::1220..."

  case partyFromText partyStr of
    None -> debug "ERROR: Invalid party"
    Some trader -> do
      -- Mint 1 ETH for swap
      ethCid <- submit trader do
        createCmd T.Token with
          issuer = trader
          owner = trader
          symbol = "ETH"
          amount = 1.0

      -- Find pool
      pools <- query @P.Pool trader
      case pools of
        ((poolCid, pool) :: _) -> do
          debug $ "Pool reserves before: ETH=" <> show pool.reserveA <> ", USDC=" <> show pool.reserveB

          -- Execute atomic swap
          let deadline = time (date 2026 Jan 1) 0 0 0
          (outputTokenCid, newPoolCid) <- submitMulti [trader, pool.poolParty] [] do
            exerciseCmd poolCid P.AtomicSwap with
              trader = trader
              traderInputTokenCid = ethCid
              inputSymbol = "ETH"
              inputAmount = 1.0
              outputSymbol = "USDC"
              minOutput = 1900.0
              maxPriceImpactBps = 500
              deadline = deadline

          -- Check new pool state
          newPools <- query @P.Pool trader
          case newPools of
            ((_, newPool) :: _) -> do
              debug $ "Pool reserves after: ETH=" <> show newPool.reserveA <> ", USDC=" <> show newPool.reserveB
              debug "SWAP SUCCESSFUL!"
            _ -> return ()
        _ -> debug "No pool found"
EOF

# Build and run
daml build -o devnet-swap.dar
daml script --dar devnet-swap.dar \
  --script-name ExecuteDevNetSwap:executeSwap \
  --ledger-host localhost \
  --ledger-port 5001
```

## ✅ STEP 6: Configure Backend for DevNet
```bash
# Update backend configuration
cd /root/cn-quickstart/quickstart/backend

# Edit application.yml
cat >> src/main/resources/application-devnet.yml << 'EOF'
ledger:
  host: localhost
  port: 5001
  admin-port: 5002
  party-id: ClearportX-DEX-1::1220...  # UPDATE WITH ACTUAL PARTY ID
EOF

# Rebuild backend
../gradlew build -x test

# Restart with DevNet profile
docker stop backend-service
docker run -d --name backend-service-devnet \
  --network host \
  -e SPRING_PROFILES_ACTIVE=devnet \
  -e LEDGER_HOST=localhost \
  -e LEDGER_PORT=5001 \
  eclipse-temurin:17 \
  bash -c 'cd /app && java -jar backend.jar'

# Copy JAR
docker cp build/libs/backend.jar backend-service-devnet:/app/backend.jar
docker restart backend-service-devnet
```

## ✅ STEP 7: Test Complete Flow on DevNet
```bash
# 1. Check pool status
curl http://localhost:8080/api/pools

# 2. Test swap via API
curl -X POST http://localhost:8080/api/swap/atomic \
  -H "X-User: ClearportX-DEX-1" \
  -H "Content-Type: application/json" \
  -d '{
    "poolId": "ETH-USDC-DEVNET",
    "inputSymbol": "ETH",
    "inputAmount": "1.0",
    "outputSymbol": "USDC",
    "minOutput": "1900.0",
    "maxPriceImpactBps": 500
  }'

# 3. Verify on Canton Explorer
# Visit: https://explorer.canton.network/
# Search for party: ClearportX-DEX-1
```

## ✅ STEP 8: Monitor & Verify
```bash
# Check contracts on ledger
daml ledger query --host localhost --port 5001

# Monitor logs
docker logs splice-validator-participant-1 --tail 50

# Check health
curl http://localhost:8080/api/health/ledger
```

## 📊 SUCCESS METRICS
- [ ] DAR uploaded to DevNet
- [ ] Pool created on chain
- [ ] Liquidity added (100 ETH / 200k USDC)
- [ ] First swap executed
- [ ] Transaction visible on Canton Explorer
- [ ] Backend connected to DevNet
- [ ] API endpoints working

## 🚨 TROUBLESHOOTING
- If port 5001 not responding: Wait 30 seconds for validator to fully start
- If DAR upload fails: Check file size, use --max-inbound-message-size
- If party not found: Use `daml ledger list-parties` to get correct ID
- If swap fails: Check multi-party authorization (trader + poolParty)

## 🎯 NEXT STEPS
1. Create more pools (CAN/USDC, ETH/CAN, etc.)
2. Test with multiple parties
3. Implement bridge for real tokens
4. Request SV vote for mainnet
5. GO LIVE!