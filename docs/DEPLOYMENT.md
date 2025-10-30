# Deployment Guide

## Local Development

1. Start Canton:
   ```bash
   docker-compose up canton
   ```

2. Deploy DAR:
   ```bash
   make deploy-local
   ```

3. Start services:
   ```bash
   make start
   ```

## DevNet Deployment

1. Configure credentials:
   ```bash
   cp config/devnet.env.example config/devnet.env
   # Edit config/devnet.env
   ```

2. Deploy:
   ```bash
   make deploy-devnet
   ```

## Production Deployment

See ARCHITECTURE.md for production deployment guide.
