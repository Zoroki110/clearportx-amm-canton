# ClearportX AMM Production DAR

## Current Production Version

**File**: `clearportx-amm-production-1.0.2.dar`  
**SHA256**: `35529180421deee57e9dfb8a75d43f5a233c90103779c6da42a50a5bc6e20d27`  
**Size**: 1.36 MB  
**Compiled**: October 28, 2025  

## Compilation Instructions

To ensure deterministic builds with stable hashes:

```bash
cd /root/cn-quickstart/quickstart/clearportx
SOURCE_DATE_EPOCH=1730000000 daml build
```

This uses a fixed timestamp to ensure the DAR hash remains consistent across builds.

## Contents

This DAR contains:
- AMM.Pool - Core liquidity pool contracts
- AMM.AtomicSwap - Direct swap functionality  
- AMM.SwapRequest - Two-step swap requests
- AMM.Receipt - Transaction receipts
- Token.Token - ERC20-like token contracts
- LPToken.LPToken - Liquidity provider tokens

## Deployment

To deploy on Canton Network DevNet:

```bash
# Upload to ledger API (port 3901 for CN Quickstart)
daml ledger upload-dar \
  --host localhost \
  --port 3901 \
  artifacts/clearportx-amm-production-1.0.2.dar
```

## Version History

- **1.0.2** - Production build with AtomicSwap functionality
- **1.0.1** - Initial DevNet deployment
