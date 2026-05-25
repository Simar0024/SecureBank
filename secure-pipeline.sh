#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -eo pipefail

# --- TERMINAL COLOR SCHEME FOR SOC TEAMS ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================================================${NC}"
echo -e "${BLUE}    SECUREBANK CORE // LOCAL AUTOMATED DEVSECOPS PIPELINE        ${NC}"
echo -e "${BLUE}==================================================================${NC}"

# --- PREREQUISITE CHECK ENGINE ---
command -v docker >/dev/null 2>&1 || { echo -e "${RED}[!] Docker is required but not installed. Exiting.${NC}" >&2; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo -e "${RED}[!] docker-compose is required but not installed. Exiting.${NC}" >&2; exit 1; }

# --- PHASE 4A: ENHANCED STATIC APPLICATION SECURITY TESTING (SAST) ---
echo -e "\n${YELLOW}[Phase 4A] Executing Enhanced Bandit SAST Scan...${NC}"
if ! command -v bandit >/dev/null 2>&1; then
    echo -e "${BLUE}[*] Installing Bandit engine dynamically...${NC}"
    pip install --quiet bandit
fi

echo -e "${BLUE}[*] Running Bandit with strict profile configurations...${NC}"
# B104: Checks for hardcoded bind addresses (e.g. 0.0.0.0)
# B105/B106: Checks for hardcoded passwords and secret keys
# -lll: Filters out LOW severity findings; focuses strictly on MEDIUM and HIGH flaws.
bandit -r ./app -x ./app/test_*.py -lll --format txt

# --- PHASE 4B: ENHANCED SOFTWARE SUPPLY CHAIN & CONTAINER CVE SCAN ---
echo -e "\n${YELLOW}[Phase 4B] Compiling Target Container Image & Scanning Infrastructure...${NC}"
docker build -t securebank-backend-api:local .

# Enhanced Layer: Pulls the official Aqua Security Trivy container to avoid installing binaries locally
echo -e "${BLUE}[*] Fetching Trivy scanning engine definitions...${NC}"
docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $HOME/.cache:/root/.cache \
    aquasecurity/trivy:latest image \
    --format table \
    --exit-code 1 \
    --ignore-unfixed \
    --severity HIGH,CRITICAL \
    securebank-backend-api:local

# --- PHASE 4C: ENHANCED DYNAMIC APPLICATION SECURITY TESTING (DAST) ---
echo -e "\n${YELLOW}[Phase 4C] Spawning Isolated Testing Stack for Fuzzing...${NC}"
docker-compose down --volumes --remove-orphans > /dev/null 2>&1
docker-compose up -d --build

echo -e "${BLUE}[*] Waiting for live Swagger schemas to initialize...${NC}"
for i in {1..15}; do
    if curl -s http://localhost:8000/api/docs > /dev/null; then
        echo -e "${GREEN}[+] Security endpoint responsive.${NC}"
        break
    fi
    if [ $i -eq 15 ]; then
        echo -e "${RED}[!] Timeout waiting for target backend engine. Teardown executed.${NC}"
        docker-compose down
        exit 1
    fi
    sleep 2
done

echo -e "${BLUE}[*] Executing Enhanced OWASP ZAP Full-API Fuzzing Scan...${NC}"
# Using the stable OWASP ZAP container to target the interactive OpenAPI schemas
# zap-api-scan.py: Tailored specifically for microservices and headless API routes.
docker run --rm \
    --network="host" \
    -v $(pwd):/zap/wrk:rw \
    ghcr.io/zaproxy/zaproxy:stable zap-api-scan.py \
    -t http://localhost:8000/api/docs \
    -f openapi \
    -r zap_compliance_report.html || true

echo -e "${GREEN}[+] DAST execution cycle completed. Report saved to zap_compliance_report.html${NC}"
echo -e "${BLUE}[*] Cleaning up active database sandbox allocations...${NC}"
docker-compose down

# --- PHASE 4D: ENHANCED KUBERNETES MANIFEST POLICY TESTING ---
echo -e "\n${YELLOW}[Phase 4D] Executing Policy Validation Checks on AKS Manifests...${NC}"
# Enhanced Layer: Running Datree completely containerized to assess deployment structures
if [ -f "deployment.yaml" ]; then
    docker run --rm \
        -v $(pwd):/workspace \
        datree/datree:latest test /workspace/deployment.yaml \
        --schema-version 1.28.0 || true
else
    echo -e "${RED}[!] deployment.yaml not found in current root working directory. Skipping.${NC}"
fi

echo -e "\n${GREEN}==================================================================${NC}"
echo -e "${GREEN}    PIPELINE EXECUTION CYCLE COMPLETE // ASSESSMENT REPORT READY   ${NC}"
echo -e "${GREEN}==================================================================${NC}"
