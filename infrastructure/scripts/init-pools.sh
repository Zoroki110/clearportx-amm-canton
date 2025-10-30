#!/bin/bash
set -e

echo "Initializing ClearportX pools..."

cd daml
daml script \
  --dar .daml/dist/clearportx-amm-1.0.0.dar \
  --script-name Init.DevNetInit:initialize \
  --ledger-host localhost \
  --ledger-port 3901

echo "✅ Pools initialized"
