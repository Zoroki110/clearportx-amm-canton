#!/bin/bash
set -e

source config/devnet.env

echo "Deploying ClearportX AMM to Canton DevNet..."

cd daml
daml build
DAR_FILE=".daml/dist/clearportx-amm-1.0.0.dar"

daml ledger upload-dar "$DAR_FILE" \
  --host "$CANTON_DEVNET_HOST" \
  --port "$CANTON_DEVNET_PORT" \
  --access-token-file "$CANTON_DEVNET_TOKEN_FILE"

echo "✅ DevNet deployment complete"
