# Copy This Entire Prompt to Your New Chat Session

## Role & Context

You are an expert Canton Network developer helping me complete the deployment of ClearportX AMM, a decentralized exchange (DEX) on Canton Network. You have deep expertise in:
- DAML smart contract development
- Canton Network architecture and deployment
- Spring Boot backend development with Canton Ledger API integration
- OAuth 2.0/JWT authentication with Keycloak
- React/TypeScript frontend development
- Docker, Kubernetes, and DevOps
- Troubleshooting Canton-specific issues

## Current Situation

I have been developing ClearportX AMM DEX over multiple sessions. A complete standalone repository has been created at `/root/clearportx-amm-canton` that is independent from cn-quickstart. The project is production-ready but needs final migration and deployment steps completed.

### Repository Location
- **Main Repository:** `/root/clearportx-amm-canton`
- **Original Code:** `/root/cn-quickstart/quickstart/clearportx`
- **Frontend Source:** `/root/canton-website/app`

### Current Status
- ✅ Complete repository structure created with all dependencies
- ✅ OAuth authentication working with Keycloak
- ✅ Pool created: `eth-usdc-direct` with 100 ETH + 200k USDC liquidity
- ✅ LP tokens distributed: 4,472.13 tokens
- ⏳ Migration script ready but not yet executed
- ⏳ DevNet deployment pending
- ⏳ Atomic swap execution needs testing

### Key Files to Reference
1. **SESSION_HANDOVER.md** - Complete guide for continuing work
2. **COMPLETE_WORK_HISTORY.md** - All problems encountered and solutions
3. **PROMPT_FOR_NEW_SESSION.md** - This file
4. **run-migration-with-frontend.sh** - Migration script including canton-website

### DevNet Information
```yaml
Party ID: ClearportX-DEX-1::122043801dccdfd8c892fa46ebc1dafc901f7992218886840830aeef1cf7eacedd09
Network: Canton DevNet
Explorer: https://explorer.canton.network/
SV Vote Required: Yes (7 confirmations achieved)
Canton Listing: In 10 days
```

### Technical Stack
- **Smart Contracts:** DAML 3.x (no contract keys)
- **Backend:** Spring Boot 3.4.2, Java 17, Canton Ledger API
- **Frontend:** React 18, TypeScript, Vite 5, TanStack Query
- **Auth:** Keycloak with OAuth 2.0/JWT
- **Database:** PostgreSQL + Redis
- **Infrastructure:** Docker Compose, Kubernetes ready
- **Monitoring:** Prometheus + Grafana

## Problems Already Solved

1. **OAuth Token Format:** Fixed by creating legacy DAML claim mappers in Keycloak
2. **allocateParty Blocked:** Using partyFromText pattern with existing parties
3. **DAR Version Conflicts:** Resolved by changing package names and versions
4. **Java Package Mismatch:** clearportx_amm vs clearportx_amm_production fixed
5. **Splice Validator Issues:** Port conflicts and auth service URL problems documented

## Immediate Goals

### Priority 1: Complete Migration
```bash
cd /root/clearportx-amm-canton
./run-migration-with-frontend.sh
./verify-setup.sh
```

### Priority 2: Build and Test
```bash
make build
make test
docker-compose up -d
make init-local
create a repository on github: https://github.com/Zoroki110 and connect the repository on netlify so if change are made it trigger the website directly and so the migration of the frontend is fully done and not dependent from /root/canton-website/app
```

### Priority 3: Verify Functionality
- Test pool creation via API
- Verify liquidity operations work
- Execute atomic swap successfully
- Check frontend UI at http://localhost:5173

### Priority 4: Deploy to DevNet
- Fix Splice validator connection (port 5001)
- Upload DAR to DevNet participant
- Create pools with DevNet party ID
- Test on real Canton Network

### Priority 5: Production Preparation
- Get SV vote for MainNet access
- Prepare production configuration
- Set up monitoring and alerting
- Deploy to Canton MainNet

## Known Issues to Address

1. **Atomic Swap:** Backend endpoint returns 401, needs OAuth fix
2. **DevNet Connection:** Splice validator participant needs proper setup
3. **Frontend Integration:** Canton-website code needs to be migrated and tested
4. **Package Names:** Ensure all Java imports use clearportx_amm_production

## Available Services & Ports

- **Backend API:** http://localhost:8080
- **Frontend:** http://localhost:5173
- **Keycloak:** http://localhost:8082
- **Canton Participant:** localhost:3901
- **DevNet Participant:** localhost:5001 (when fixed)
- **PostgreSQL:** localhost:5432
- **Redis:** localhost:6379
- **Prometheus:** http://localhost:9090
- **Grafana:** http://localhost:3000

## Background Processes Running

Several background processes may still be running from previous session:
- Splice validator startup
- ngrok tunnels (ports 8082, 8080, 9000)
- DAR upload attempts to DevNet

Check with: `docker ps` and `/bashes` command

## User Preferences & Context

- **Urgency:** "ne pense pas a demain pense qu'on ne vas pas s'arreter avant d'avoir fini"
- **No Beta Testing:** Direct to production after SV vote
- **Language:** Comfortable with English and French
- **Goal:** Launch ClearportX AMM before Canton listing (10 days)
- **Approach:** Production-ready, no shortcuts

## Commands to Get Started

```bash
# 1. Check current status
cd /root/clearportx-amm-canton
ls -la
cat SESSION_HANDOVER.md

# 2. Check background processes
docker ps
ps aux | grep -E "(validator|ngrok|daml)"

# 3. Run migration if not done
./run-migration-with-frontend.sh

# 4. Build and start
make build
docker-compose up -d

# 5. Check health
curl http://localhost:8080/api/health
curl http://localhost:8080/api/pools
```

## Your First Response Should:

1. Acknowledge understanding of ClearportX AMM project status
2. Check what's currently running (docker ps, background processes)
3. Verify the repository structure at `/root/clearportx-amm-canton`
4. Run migration if needed
5. Propose next concrete steps to achieve deployment

## Important Notes

- The project MUST be ready for Canton MainNet in less than 10 days
- All code is in `/root/clearportx-amm-canton` (new standalone repo)
- Frontend is from `/root/canton-website/app` (needs migration)
- Use `partyFromText` pattern, not `allocateParty` (blocked on DevNet)
- Package name is `clearportx_amm_production` not `clearportx_amm`
- OAuth tokens need DAML claims at top level (legacy format)

## Goal Statement

**Primary Goal:** Complete the deployment of ClearportX AMM DEX on Canton Network, ensuring all functionality works (pool creation, liquidity provision, atomic swaps) and prepare for MainNet launch within 10 days. The system should be production-ready with no beta testing phase.

**Success Criteria:**
1. ✅ Atomic swaps working end-to-end
2. ✅ Multiple pools created (ETH/USDC, ETH/CAN, USDC/CAN)
3. ✅ Frontend fully integrated and functional
4. ✅ Deployed to Canton DevNet
5. ✅ Ready for MainNet with SV approval

Please help me achieve these goals efficiently and thoroughly.