#!/bin/bash
set -e

echo "Deploying ClearportX AMM to local Canton..."

# Build DAR
cd daml
daml build
DAR_FILE=".daml/dist/clearportx-amm-1.0.0.dar"

# Upload to Canton
daml ledger upload-dar "$DAR_FILE" \
  --host localhost \
  --port 3901

echo "✅ Deployment complete"
