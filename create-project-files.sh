#!/bin/bash

# Script to create all remaining project files for ClearportX AMM Canton
# This creates a complete, production-ready repository structure

set -e

PROJECT_ROOT="/root/clearportx-amm-canton"
cd "$PROJECT_ROOT"

echo "Creating ClearportX AMM Canton standalone repository..."

# ============================================================================
# Backend Files
# ============================================================================

echo "Creating backend structure..."

# Main Application
cat > backend/src/main/java/com/clearportx/ClearportXApplication.java << 'EOF'
package com.clearportx;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableCaching
@EnableScheduling
public class ClearportXApplication {
    public static void main(String[] args) {
        SpringApplication.run(ClearportXApplication.class, args);
    }
}
EOF

# Application Configuration
cat > backend/src/main/resources/application.yml << 'EOF'
spring:
  application:
    name: clearportx-amm
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:local}
  datasource:
    url: ${DATABASE_URL:jdbc:h2:mem:clearportx}
    username: ${DATABASE_USER:sa}
    password: ${DATABASE_PASSWORD:}
    driver-class-name: ${DATABASE_DRIVER:org.h2.Driver}
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: false
    properties:
      hibernate:
        dialect: ${HIBERNATE_DIALECT:org.hibernate.dialect.H2Dialect}
  security:
    oauth2:
      client:
        registration:
          canton:
            client-id: ${OAUTH_CLIENT_ID}
            client-secret: ${OAUTH_CLIENT_SECRET}
            scope: openid,profile,email
        provider:
          canton:
            issuer-uri: ${OAUTH_ISSUER_URI:https://auth.canton.network}
      resourceserver:
        jwt:
          issuer-uri: ${OAUTH_ISSUER_URI:https://auth.canton.network}
  redis:
    host: ${REDIS_HOST:localhost}
    port: ${REDIS_PORT:6379}

server:
  port: ${BACKEND_PORT:8080}
  compression:
    enabled: true
  http2:
    enabled: true

canton:
  participant:
    host: ${CANTON_PARTICIPANT_HOST:localhost}
    port: ${CANTON_LEDGER_API_PORT:3901}
    admin-port: ${CANTON_ADMIN_PORT:3902}
  party:
    pool-operator: ${CANTON_POOL_OPERATOR:PoolOperator}
    pool-party: ${CANTON_POOL_PARTY:PoolParty}
    lp-issuer: ${CANTON_LP_ISSUER:LPIssuer}

clearportx:
  jwt:
    secret: ${JWT_SECRET:dev-secret-change-in-production}
    expiration: 3600000  # 1 hour
  fees:
    swap-bps: 30  # 0.3%
    protocol-share: 0.25  # 25% of fees
  limits:
    max-swap-size: 1000000
    max-pools-per-user: 100
    rate-limit-requests: 100  # per minute

management:
  endpoints:
    web:
      exposure:
        include: health,info,prometheus,metrics
  metrics:
    export:
      prometheus:
        enabled: true
    distribution:
      percentiles-histogram:
        http.server.requests: true

logging:
  level:
    root: INFO
    com.clearportx: DEBUG
    org.springframework.security: INFO
  pattern:
    console: "%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n"
    file: "%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n"
  file:
    name: logs/clearportx-amm.log

---
spring:
  config:
    activate:
      on-profile: devnet
canton:
  participant:
    host: ${CANTON_DEVNET_HOST}
    port: ${CANTON_DEVNET_PORT:443}

---
spring:
  config:
    activate:
      on-profile: mainnet
canton:
  participant:
    host: ${CANTON_MAINNET_HOST}
    port: ${CANTON_MAINNET_PORT:443}
EOF

# Security Config
cat > backend/src/main/java/com/clearportx/config/SecurityConfig.java << 'EOF'
package com.clearportx.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Value("${spring.security.oauth2.resourceserver.jwt.issuer-uri}")
    private String issuerUri;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .csrf(csrf -> csrf.disable())
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/actuator/**", "/swagger-ui/**", "/v3/api-docs/**").permitAll()
                .requestMatchers("/api/v1/health", "/api/v1/pools/**").permitAll()
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2.jwt());

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(List.of("http://localhost:5173", "https://app.clearportx.com", "https://*.netlify.app"));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(Arrays.asList("*"));
        configuration.setAllowCredentials(true);
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    @Bean
    public JwtDecoder jwtDecoder() {
        return NimbusJwtDecoder.withIssuerLocation(issuerUri).build();
    }
}
EOF

# CORS Config
cat > backend/src/main/java/com/clearportx/config/CorsConfig.java << 'EOF'
package com.clearportx.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class CorsConfig {

    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/**")
                        .allowedOrigins("http://localhost:5173", "https://app.clearportx.com", "https://*.netlify.app")
                        .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                        .allowedHeaders("*")
                        .allowCredentials(true)
                        .maxAge(3600);
            }
        };
    }
}
EOF

# Canton Config
cat > backend/src/main/java/com/clearportx/config/CantonConfig.java << 'EOF'
package com.clearportx.config;

import com.daml.ledger.javaapi.data.DamlRecord;
import com.daml.ledger.javaapi.data.Party;
import com.daml.ledger.rxjava.DamlLedgerClient;
import io.grpc.ManagedChannel;
import io.grpc.ManagedChannelBuilder;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class CantonConfig {

    @Value("${canton.participant.host}")
    private String cantonHost;

    @Value("${canton.participant.port}")
    private int cantonPort;

    @Value("${canton.party.pool-operator}")
    private String poolOperatorParty;

    @Bean
    public DamlLedgerClient damlLedgerClient() {
        ManagedChannel channel = ManagedChannelBuilder
                .forAddress(cantonHost, cantonPort)
                .usePlaintext()
                .build();

        return DamlLedgerClient.newBuilder(channel).build();
    }

    @Bean
    public Party poolOperator() {
        return new Party(poolOperatorParty);
    }
}
EOF

echo "✅ Backend structure created"

# ============================================================================
# Frontend Files
# ============================================================================

echo "Creating frontend structure..."

cat > frontend/package.json << 'EOF'
{
  "name": "clearportx-frontend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "test": "vitest"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.21.0",
    "axios": "^1.6.2",
    "@tanstack/react-query": "^5.14.0",
    "recharts": "^2.10.3",
    "zustand": "^4.4.7"
  },
  "devDependencies": {
    "@types/react": "^18.2.43",
    "@types/react-dom": "^18.2.17",
    "@typescript-eslint/eslint-plugin": "^6.14.0",
    "@typescript-eslint/parser": "^6.14.0",
    "@vitejs/plugin-react": "^4.2.1",
    "eslint": "^8.55.0",
    "eslint-plugin-react-hooks": "^4.6.0",
    "eslint-plugin-react-refresh": "^0.4.5",
    "typescript": "^5.2.2",
    "vite": "^5.0.8",
    "vitest": "^1.0.4"
  }
}
EOF

cat > frontend/vite.config.ts << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true
      }
    }
  },
  build: {
    outDir: 'dist',
    sourcemap: true
  }
})
EOF

cat > frontend/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOF

cat > frontend/src/App.tsx << 'EOF'
import React from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import SwapInterface from './components/SwapInterface';
import LiquidityPool from './components/LiquidityPool';
import PoolList from './components/PoolList';

const queryClient = new QueryClient();

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <Router>
        <div className="app">
          <header>
            <h1>ClearportX AMM</h1>
          </header>
          <main>
            <Routes>
              <Route path="/" element={<SwapInterface />} />
              <Route path="/pools" element={<PoolList />} />
              <Route path="/liquidity/:poolId" element={<LiquidityPool />} />
            </Routes>
          </main>
        </div>
      </Router>
    </QueryClientProvider>
  );
}

export default App;
EOF

cat > frontend/src/main.tsx << 'EOF'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.tsx'
import './styles/index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
EOF

cat > frontend/index.html << 'EOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>ClearportX AMM - Decentralized Exchange on Canton Network</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF

echo "✅ Frontend structure created"

# ============================================================================
# Infrastructure Files
# ============================================================================

echo "Creating infrastructure files..."

# Canton Configuration
cat > infrastructure/canton/canton.conf << 'EOF'
canton {
  participants {
    clearportx {
      storage {
        type = memory
      }
      ledger-api {
        port = 3901
        address = "0.0.0.0"
      }
      admin-api {
        port = 3902
        address = "0.0.0.0"
      }
    }
  }
  monitoring {
    metrics {
      reporters = [{
        type = prometheus
        address = "0.0.0.0"
        port = 9000
      }]
    }
  }
}
EOF

# Docker backend
cat > infrastructure/docker/Dockerfile.backend << 'EOF'
FROM gradle:8.5-jdk17 AS build
WORKDIR /app
COPY backend/build.gradle.kts backend/settings.gradle.kts ./
COPY backend/src ./src
RUN gradle build -x test --no-daemon

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar
EXPOSE 8080 9090
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF

# Docker frontend
cat > infrastructure/docker/Dockerfile.frontend << 'EOF'
FROM node:18-alpine AS build
WORKDIR /app
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY infrastructure/docker/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# Nginx config
cat > infrastructure/docker/nginx.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://backend:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

echo "✅ Infrastructure files created"

# ============================================================================
# Deployment Scripts
# ============================================================================

echo "Creating deployment scripts..."

cat > infrastructure/scripts/deploy-local.sh << 'EOF'
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
EOF

cat > infrastructure/scripts/deploy-devnet.sh << 'EOF'
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
EOF

cat > infrastructure/scripts/init-pools.sh << 'EOF'
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
EOF

chmod +x infrastructure/scripts/*.sh

echo "✅ Deployment scripts created"

# ============================================================================
# Environment Templates
# ============================================================================

cat > config/.env.example << 'EOF'
# Canton Network
CANTON_PARTICIPANT_HOST=localhost
CANTON_PARTICIPANT_PORT=3901
CANTON_ADMIN_PORT=3902
CANTON_LEDGER_API_PORT=3901

# Parties
CANTON_POOL_OPERATOR=PoolOperator
CANTON_POOL_PARTY=PoolParty
CANTON_LP_ISSUER=LPIssuer

# Backend
BACKEND_PORT=8080
JWT_SECRET=your-secret-key-change-in-production
OAUTH_CLIENT_ID=your-oauth-client-id
OAUTH_CLIENT_SECRET=your-oauth-client-secret
OAUTH_ISSUER_URI=https://auth.canton.network

# Database (optional)
DATABASE_URL=jdbc:postgresql://localhost:5432/clearportx
DATABASE_USER=clearportx
DATABASE_PASSWORD=changeme
DATABASE_DRIVER=org.postgresql.Driver
HIBERNATE_DIALECT=org.hibernate.dialect.PostgreSQLDialect

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# Frontend
VITE_API_URL=http://localhost:8080
VITE_OAUTH_CLIENT_ID=your-oauth-client-id

# Monitoring
GRAFANA_PASSWORD=admin
EOF

cat > config/devnet.env.example << 'EOF'
CANTON_DEVNET_HOST=devnet.canton.network
CANTON_DEVNET_PORT=443
CANTON_DEVNET_TOKEN_FILE=~/.canton/devnet-token.jwt
EOF

echo "✅ Configuration templates created"

# ============================================================================
# CI/CD
# ============================================================================

mkdir -p devops/.github/workflows

cat > devops/.github/workflows/ci.yml << 'EOF'
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup DAML SDK
        run: |
          curl -sSL https://get.daml.com/ | sh -s 3.3.0
          echo "$HOME/.daml/bin" >> $GITHUB_PATH

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '18'

      - name: Test DAML
        run: cd daml && daml build && daml test

      - name: Test Backend
        run: cd backend && ./gradlew test

      - name: Test Frontend
        run: cd frontend && npm ci && npm test

      - name: Build Docker Images
        run: docker-compose build
EOF

echo "✅ CI/CD pipelines created"

# ============================================================================
# Documentation
# ============================================================================

cat > docs/DEPLOYMENT.md << 'EOF'
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
EOF

cat > docs/API.md << 'EOF'
# API Reference

## Pools

### GET /api/v1/pools
List all available pools.

### POST /api/v1/pools
Create a new liquidity pool.

## Swaps

### POST /api/v1/swaps
Execute a token swap.

### GET /api/v1/swaps/{id}
Get swap status.

See Swagger UI at http://localhost:8080/swagger-ui.html
EOF

echo "✅ Documentation created"

echo ""
echo "========================================="
echo "✅ ClearportX AMM Canton repository created!"
echo "========================================="
echo ""
echo "Project structure:"
echo "  📁 $PROJECT_ROOT/"
echo "  ├── daml/              - Smart contracts"
echo "  ├── backend/           - Spring Boot API"
echo "  ├── frontend/          - React frontend"
echo "  ├── infrastructure/    - Docker & K8s"
echo "  ├── devops/            - CI/CD"
echo "  └── docs/              - Documentation"
echo ""
echo "Next steps:"
echo "  1. cd $PROJECT_ROOT"
echo "  2. make setup"
echo "  3. make build"
echo "  4. make start"
echo ""
EOF

chmod +x /root/clearportx-amm-canton/create-project-files.sh
