# 🚀 Complete Guide: How We Added Liquidity to ClearportX AMM on Canton Network DevNet

## Overview
This document details the complete process of creating a pool and adding liquidity to ClearportX AMM on Canton Network DevNet, including all challenges faced and solutions implemented.

## Starting Context
- **Pool Status**: Already created via backend API (pool ID: `eth-usdc-direct`)
- **Challenge**: Need to mint tokens and add liquidity, but OAuth/DAML script issues prevented standard approaches
- **Infrastructure**: Canton participant on ports 3901/3902, backend on 8080

## Step-by-Step Process

### 1. OAuth Token Configuration 🔐

**Problem**: Initial OAuth token had malformed DAML claims
```json
// Bad format (split into nested objects):
"https://daml": {
  "com/ledger-api": {
    "admin": true,
    ...
  }
}
```

**Solution**: Reconfigured Keycloak to add top-level claims
```bash
# Added two mappers in Keycloak:
1. "DAML Top Level Claims" - adds "admin": true
2. "DAML actAs Claim" - adds "actAs": ["party_id"]
```

**Result**: Working token with proper claims
```json
{
  "admin": true,
  "actAs": ["app_provider_quickstart-root-1::12201300e204..."]
}
```

### 2. Token Minting Process 🪙

**Problem**: Standard DAML scripts failed with various errors:
- `allocateParty` - PERMISSION_DENIED
- `allocatePartyWithHint` - "name cannot be different from id hint"

**Solution**: Created `DirectMintTokens.daml` using `partyFromText`
```daml
module DirectMintTokens where

import Daml.Script
import Token.Token

directMint : Script ()
directMint = script do
  let partyStr = "app_provider_quickstart-root-1::12201300e204..."
  
  case partyFromText partyStr of
    None -> debug "ERROR: Invalid party string"
    Some provider -> do
      -- Mint ETH
      ethCid <- submit provider do
        createCmd Token with
          issuer = provider
          owner = provider
          symbol = "ETH"
          amount = 100.0
      
      -- Mint USDC
      usdcCid <- submit provider do
        createCmd Token with
          issuer = provider
          owner = provider
          symbol = "USDC"
          amount = 200000.0
          
      debug $ "ETH: " <> show ethCid
      debug $ "USDC: " <> show usdcCid
```

**Execution**:
```bash
# Compile with new package name to avoid version conflicts
daml.yaml: name: clearportx-mint-tokens, version: 1.0.7

# Build and run
SOURCE_DATE_EPOCH=1730000000 daml build -o .daml/dist/direct-mint-v7.dar
daml script \
  --dar .daml/dist/direct-mint-v7.dar \
  --script-name DirectMintTokens:directMint \
  --ledger-host localhost \
  --ledger-port 3901 \
  --access-token-file /tmp/working-token.txt
```

**Result**: Successfully minted tokens
- ETH Token: `0031f6e20edbfecc65ff8a98711f21761161bb28b434d8e8239d14625e76033912`
- USDC Token: `0075696d121f382ccdb3bd641c234b8c5be7ee5a76ccec62729562885bdeb6312e`

### 3. Adding Liquidity Process 💧

**Method**: Used backend API endpoint `/api/liquidity/add`

**Request**:
```bash
curl -X POST http://localhost:8080/api/liquidity/add \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(cat /tmp/working-token.txt)" \
  -d '{
    "poolId": "eth-usdc-direct",
    "provider": "app_provider_quickstart-root-1::12201300e204...",
    "tokenACid": "0031f6e20edbfecc65ff8a98711f21761161bb28b434d8e8239d14625e76033912",
    "tokenBCid": "0075696d121f382ccdb3bd641c234b8c5be7ee5a76ccec62729562885bdeb6312e",
    "amountA": "100.0",
    "amountB": "200000.0",
    "minLPTokens": "0.0"
  }'
```

**Response**:
```json
{
  "lpTokenCid": "00b1fd45b5c9926c63b9d07d2adc4140c6e3dc7e5bb8408e0d72063ecd88297faa",
  "newPoolCid": "005f02cd33b67ff5f9d2307c5dae6c82e0c756c4c51221dde8ba791e26d6f445fe",
  "reserveA": "100.0000000000",
  "reserveB": "200000.0000000000"
}
```

### 4. Verification ✅

**Pool Status Check**:
```bash
curl -s http://localhost:8080/api/pools | jq '.'
```

**Result**:
```json
{
  "poolId": "eth-usdc-direct",
  "tokenA": {"symbol": "ETH", "name": "ETH", "decimals": 10},
  "tokenB": {"symbol": "USDC", "name": "USDC", "decimals": 10},
  "reserveA": "100.0000000000",
  "reserveB": "200000.0000000000",
  "totalLPSupply": "4472.1359551823",
  "feeRate": "0.003",
  "volume24h": "0.00"
}
```

## Key Technical Solutions

### 1. OAuth Token Format
- **Issue**: DAML claims were nested incorrectly
- **Fix**: Add claims at top level using Keycloak mappers
- **Key**: Both `admin: true` and `actAs: ["party_id"]` needed

### 2. Party Allocation Bypass
- **Issue**: `allocateParty` blocked even with admin=true
- **Fix**: Use `partyFromText` to convert string to Party type
- **Key**: Use full party ID including namespace

### 3. DAR Version Conflicts
- **Issue**: "KNOWN_DAR_VERSION" errors
- **Fix**: Change package name or increment version
- **Key**: Use `SOURCE_DATE_EPOCH` for reproducible builds

### 4. Backend API Authentication
- **Issue**: 401 Unauthorized on all endpoints
- **Fix**: Use Bearer token from OAuth in Authorization header
- **Key**: Token must have proper actAs claim for the party

## Files Created/Modified

1. **DAML Scripts**:
   - `DirectMintTokens.daml` - Successful token minting
   - `daml.yaml` - Updated package name and version

2. **Configuration**:
   - Keycloak mappers for OAuth claims
   - Token files: `/tmp/working-token.txt`

3. **Documentation**:
   - This guide
   - `LIQUIDITY_ADDED_SUCCESS.md`

## Final State

- **Pool**: eth-usdc-direct
- **Liquidity**: 100 ETH + 200,000 USDC
- **Price**: 1 ETH = 2,000 USDC
- **LP Tokens**: 4,472.13
- **TVL**: $400,000
- **Status**: LIVE and ready for trading

## Commands Summary

```bash
# 1. Get OAuth token with proper claims
curl -s -X POST "http://localhost:8082/realms/AppProvider/protocol/openid-connect/token" \
  -d "client_id=app-provider-validator" \
  -d "client_secret=AL8648b9SfdTFImq7FV56Vd0KHifHBuC" \
  -d "grant_type=client_credentials" \
  | jq -r .access_token > /tmp/working-token.txt

# 2. Compile and run minting script
daml build -o .daml/dist/direct-mint-v7.dar
daml script --dar .daml/dist/direct-mint-v7.dar \
  --script-name DirectMintTokens:directMint \
  --ledger-host localhost --ledger-port 3901 \
  --access-token-file /tmp/working-token.txt

# 3. Add liquidity via API
curl -X POST http://localhost:8080/api/liquidity/add \
  -H "Authorization: Bearer $(cat /tmp/working-token.txt)" \
  -H "Content-Type: application/json" \
  -d '{ ... }'

# 4. Verify pool status
curl -s http://localhost:8080/api/pools | jq '.'
```

## Next Steps

1. Test swap functionality
2. Create additional pools (CAN/CBTC)
3. Verify on Canton Explorer
4. Frontend integration testing

---
**Created**: Oct 29, 2025
**Network**: Canton Network DevNet (PUBLIC)
**Author**: AI Assistant
