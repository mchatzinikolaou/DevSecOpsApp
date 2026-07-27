# DevSecOpsApp - DevSecOps Pipeline

## Quick Start
How to run:

# Check you have these installed:
docker --version
docker-compose --version
dotnet --version  # Should be 8.0+

#Install Git-hooks
cd $PathToRepo
bash git-hooks/install-hooks.sh

# Run Static Analysis 
## Create reports directory
mkdir -p reports

## 1. Dependency Scan
dotnet list package --vulnerable > reports/dependencies.txt 2>&1

## 2. Semgrep (Code Analysis)
docker run --rm -v "${PWD}:/src" -w /src returntocorp/semgrep:latest semgrep --config=auto . > reports/semgrep.txt 2>&1

## 3. TruffleHog (Secret Detection)
docker run --rm -v "${PWD}:/repo" trufflesecurity/trufflehog:latest filesystem /repo > reports/trufflehog.txt 2>&1

# Build and run application
## Start the application containers
docker-compose up -d --build

## Wait for startup
timeout /t 15

## Verify app is running
curl http://localhost:8080/WeatherForecast

# Run Dynamic Tests
# 1. Port Scanning (Nmap)
docker run --rm --network host networkstatic/nmap:latest nmap -sV -p- localhost > reports/nmap.txt 2>&1

# 2. SQL Injection Testing (sqlmap)
docker run --rm --network host secsi/sqlmap:latest sqlmap.py --batch -u "http://localhost:8080/api/login" --method POST --data "{\"Username\":\"admin\", \"Password\":\"password\"}" --headers "Content-Type: application/json" > reports/sqlmap.txt 2>&1

# Check Results
type reports\dependencies.txt
type reports\semgrep.txt
type reports\trufflehog.txt
type reports\nmap.txt
type reports\sqlmap.txt

# Cleanup
docker-compose down
