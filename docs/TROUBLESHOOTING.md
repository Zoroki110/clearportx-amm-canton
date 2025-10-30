# Troubleshooting Guide

## Common Issues and Solutions

### Canton Connection Issues

#### Problem: "Cannot connect to Canton participant"
```
ERROR: Failed to connect to localhost:3901
```

**Solutions:**
1. Check Canton is running:
   ```bash
   curl http://localhost:3902/health
   ```

2. Verify ports are correct:
   ```bash
   docker ps | grep canton
   ```

3. Check firewall rules:
   ```bash
   sudo ufw status
   ```

4. Review Canton logs:
   ```bash
   docker logs clearportx-canton
   ```

#### Problem: "DAR upload failed"
```
ERROR: Package upload rejected
```

**Solutions:**
1. Verify DAR file exists:
   ```bash
   ls -la daml/.daml/dist/*.dar
   ```

2. Check Canton participant ID matches:
   ```bash
   ./infrastructure/scripts/check-participant.sh
   ```

3. Ensure no duplicate package:
   ```bash
   daml ledger list-packages --host localhost --port 3901
   ```

### Build Issues

#### Problem: "DAML build fails"
```
ERROR: Type mismatch in Pool.daml
```

**Solutions:**
1. Clean and rebuild:
   ```bash
   cd daml
   rm -rf .daml/dist
   daml build
   ```

2. Check DAML SDK version:
   ```bash
   daml version
   # Should be 3.3.0 or higher
   ```

3. Verify all imports:
   ```bash
   grep -r "^import" daml/
   ```

#### Problem: "Backend build fails"
```
ERROR: Could not resolve dependencies
```

**Solutions:**
1. Clean Gradle cache:
   ```bash
   cd backend
   ./gradlew clean build --refresh-dependencies
   ```

2. Check Java version:
   ```bash
   java -version
   # Should be Java 17
   ```

3. Verify Gradle wrapper:
   ```bash
   ./gradlew --version
   ```

#### Problem: "Frontend build fails"
```
ERROR: Module not found
```

**Solutions:**
1. Clean and reinstall:
   ```bash
   cd frontend
   rm -rf node_modules package-lock.json
   npm install
   ```

2. Check Node version:
   ```bash
   node --version
   # Should be 18.x or higher
   ```

### Runtime Issues

#### Problem: "Swap fails with 'Insufficient reserves'"
**Cause:** Pool doesn't have enough liquidity

**Solutions:**
1. Check pool reserves:
   ```bash
   curl http://localhost:8080/api/v1/pools/{poolId}
   ```

2. Add liquidity:
   ```bash
   curl -X POST http://localhost:8080/api/v1/pools/{poolId}/liquidity \
     -H "Content-Type: application/json" \
     -d '{
       "amountA": 100,
       "amountB": 300000,
       "minLPTokens": 1000
     }'
   ```

#### Problem: "Slippage too high"
```
ERROR: Min output not met (slippage)
```

**Solutions:**
1. Increase slippage tolerance:
   ```javascript
   // Frontend
   const minOutput = expectedOutput * 0.95; // 5% slippage
   ```

2. Reduce swap size
3. Wait for better liquidity

#### Problem: "Authentication failed"
```
401 Unauthorized
```

**Solutions:**
1. Check JWT token:
   ```bash
   curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://localhost:8080/api/v1/pools
   ```

2. Verify OAuth configuration:
   ```bash
   grep OAUTH .env
   ```

3. Regenerate token:
   ```bash
   # Login again via OAuth flow
   ```

### Database Issues

#### Problem: "Database connection failed"
```
ERROR: Could not connect to PostgreSQL
```

**Solutions:**
1. Check PostgreSQL is running:
   ```bash
   docker ps | grep postgres
   ```

2. Verify credentials:
   ```bash
   psql -h localhost -U clearportx -d clearportx
   ```

3. Check connection string:
   ```bash
   grep DATABASE_URL .env
   ```

#### Problem: "Schema migration failed"
```
ERROR: Flyway migration failed
```

**Solutions:**
1. Reset database:
   ```bash
   cd backend
   ./gradlew flywayClean flywayMigrate
   ```

2. Or manually drop and recreate:
   ```sql
   DROP DATABASE clearportx;
   CREATE DATABASE clearportx;
   ```

### Docker Issues

#### Problem: "Container won't start"
```
ERROR: Exited with code 1
```

**Solutions:**
1. Check logs:
   ```bash
   docker logs clearportx-backend
   ```

2. Verify environment variables:
   ```bash
   docker exec clearportx-backend env
   ```

3. Rebuild image:
   ```bash
   docker-compose build --no-cache backend
   docker-compose up -d
   ```

#### Problem: "Port already in use"
```
ERROR: Bind for 0.0.0.0:8080 failed: port is already allocated
```

**Solutions:**
1. Find process using port:
   ```bash
   lsof -i :8080
   ```

2. Kill process:
   ```bash
   kill -9 PID
   ```

3. Or change port in docker-compose.yml

### Performance Issues

#### Problem: "Slow API responses"
**Solutions:**
1. Enable Redis caching:
   ```yaml
   # application.yml
   spring:
     cache:
       type: redis
   ```

2. Check database indexes:
   ```sql
   EXPLAIN ANALYZE SELECT * FROM pools;
   ```

3. Monitor metrics:
   ```bash
   curl http://localhost:8080/actuator/metrics
   ```

#### Problem: "High memory usage"
**Solutions:**
1. Increase JVM heap:
   ```bash
   JAVA_OPTS="-Xmx2g -Xms512m"
   ```

2. Check for memory leaks:
   ```bash
   jmap -heap PID
   ```

3. Enable GC logging:
   ```bash
   -XX:+PrintGCDetails -XX:+PrintGCTimeStamps
   ```

### Deployment Issues

#### Problem: "DevNet deployment fails"
```
ERROR: Access denied
```

**Solutions:**
1. Verify DevNet credentials:
   ```bash
   cat config/devnet.env
   ```

2. Check token expiry:
   ```bash
   jwt decode $(cat ~/.canton/devnet-token.jwt)
   ```

3. Regenerate access token from Canton DevNet portal

#### Problem: "Kubernetes deployment fails"
```
ERROR: ImagePullBackOff
```

**Solutions:**
1. Check image exists:
   ```bash
   docker images | grep clearportx
   ```

2. Push to registry:
   ```bash
   docker tag clearportx-backend:latest registry.example.com/clearportx-backend:latest
   docker push registry.example.com/clearportx-backend:latest
   ```

3. Update image pull secrets:
   ```bash
   kubectl create secret docker-registry regcred \
     --docker-server=registry.example.com \
     --docker-username=user \
     --docker-password=pass
   ```

## Debugging Tips

### Enable Debug Logging
```yaml
# application.yml
logging:
  level:
    com.clearportx: DEBUG
    com.daml: DEBUG
```

### Canton Script Debugging
```daml
-- Add debug statements
debug "Pool reserves:" <> show (reserveA, reserveB)
debug "Calculated output:" <> show output
```

### gRPC Debugging
```bash
# Enable gRPC logging
export GRPC_VERBOSITY=DEBUG
export GRPC_TRACE=all
```

### Frontend Debugging
```javascript
// Enable React DevTools
if (process.env.NODE_ENV === 'development') {
  console.log('Pool state:', pool);
}
```

## Health Checks

### Backend Health
```bash
curl http://localhost:8080/actuator/health
```

### Canton Health
```bash
curl http://localhost:3902/health
```

### Database Health
```bash
pg_isready -h localhost -p 5432
```

### Full System Check
```bash
make health
```

## Getting Help

1. **Check Logs:**
   ```bash
   # Application logs
   tail -f logs/clearportx-amm.log

   # Docker logs
   docker-compose logs -f

   # Canton logs
   docker logs clearportx-canton
   ```

2. **Review Documentation:**
   - [Architecture](ARCHITECTURE.md)
   - [API Reference](API.md)
   - [Deployment Guide](DEPLOYMENT.md)

3. **Community Support:**
   - GitHub Issues: [Report a bug]
   - Canton Forums: [https://discuss.canton.network]
   - Discord: [Join our Discord]

4. **Professional Support:**
   - Email: support@clearportx.com
   - Enterprise support: enterprise@clearportx.com

## Reporting Bugs

When reporting issues, include:
1. Error message and stack trace
2. Steps to reproduce
3. Environment details (OS, versions)
4. Relevant logs
5. Expected vs actual behavior

Template:
```markdown
**Environment:**
- OS: Ubuntu 22.04
- Canton SDK: 3.3.0
- Java: 17
- Node: 18.16.0

**Steps to Reproduce:**
1. Deploy to DevNet
2. Execute swap
3. Error occurs

**Error:**
<error message>

**Logs:**
<relevant logs>
```
