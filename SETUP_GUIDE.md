# DevSecOpsApp Setup & Quick Start Guide

## Prerequisites

### Required Software
- Docker Desktop or Docker Engine (version 20.10+)
- Docker Compose (version 2.0+)
- .NET 8 SDK (for local development)
- Git (version 2.20+)
- Jenkins (for CI/CD - optional for local testing)

### Minimum System Requirements
- 4GB RAM (8GB+ recommended)
- 20GB free disk space (for Docker images)
- Linux, macOS, or Windows with WSL2

### Installation Verification
```bash
# Check versions
docker --version
docker-compose --version
dotnet --version
git --version
```

---

## Local Setup (5-10 minutes)

### Step 1: Clone Repository
```bash
git clone https://github.com/mchatzinikolaou/DevSecOpsApp.git
cd DevSecOpsApp
```

### Step 2: Configure Git Hooks
```bash
# Configure Git to use hooks from .husky directory
git config core.hooksPath .husky

# Make hooks executable
chmod +x .husky/pre-commit
chmod +x .husky/pre-push

# Verify installation
git config core.hooksPath  # Should output: .husky
```

### Step 3: Build Docker Image
```bash
# Build the application Docker image
docker build -t devsecopsapp:latest -f Dockerfile .

# Verify the image was created
docker images | grep devsecopsapp
```

**Expected output**: Image `devsecopsapp:latest` appears in the list

### Step 4: Start Application
```bash
# Start the application using docker-compose
docker-compose up -d

# Check if container is running
docker ps | grep devsecopsapp

# View logs
docker-compose logs -f devsecopsapp
```

**Expected output**: 
- Container is listed as "Up"
- Logs show ASP.NET Core starting
- "Application started" message

### Step 5: Verify Application is Running
```bash
# Test Swagger UI (should return HTML)
curl http://localhost:8080/swagger/index.html -s | head -n 20

# Or access via browser
open http://localhost:8080/swagger/index.html  # macOS
xdg-open http://localhost:8080/swagger/index.html  # Linux
start http://localhost:8080/swagger/index.html  # Windows
```

**Expected output**: Swagger UI should be accessible

### Step 6: Test Vulnerable Endpoints

#### Test SQL Injection Endpoint
```bash
# Normal login (safe)
curl -X POST http://localhost:8080/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}'

# SQL Injection attempt (vulnerable)
curl -X POST http://localhost:8080/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin'\'' OR '\''1'\''='\''1","password":"anything"}'
```

#### Test Command Injection Endpoint
```bash
# Safe command
curl -X POST http://localhost:8080/api/command/execute \
  -H "Content-Type: application/json" \
  -d '{"command":"id"}'

# Dangerous command (reads /etc/passwd)
curl -X POST http://localhost:8080/api/command/execute \
  -H "Content-Type: application/json" \
  -d '{"command":"cat /etc/passwd"}'
```

**Expected output**: Commands execute in the container

### Step 7: Cleanup
```bash
# Stop and remove containers
docker-compose down

# Remove images (optional)
docker rmi devsecopsapp:latest
```

---

## Running Security Scans Locally

### Quick Scan (10 minutes)
```bash
# 1. Dependency scanning
dotnet list package --vulnerable

# 2. Build Docker image (if not already built)
docker build -t devsecopsapp:latest -f Dockerfile .

# 3. Container scanning
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy:latest image devsecopsapp:latest
```

### Full Scan (20-30 minutes)

Ensure application is running with `docker-compose up -d` first.

```bash
# 1. Port scanning
docker run --rm --network host \
    networkstatic/nmap:latest \
    nmap -sV -p- localhost

# 2. Web app scanning (OWASP ZAP)
mkdir -p reports
docker run --rm --network host \
    -v $(pwd)/reports:/zap/results \
    -t ghcr.io/zaproxy/zaproxy:stable \
    zap-baseline.py \
    -t http://localhost:8080 \
    -J /zap/results/zap-findings.json \
    -r /zap/results/zap-findings.html || true

# 3. SQL Injection testing
docker run --rm --network host \
    sqlmap/sqlmap:latest \
    sqlmap.py \
    --batch \
    -u "http://localhost:8080/api/login" \
    --method POST \
    --data '{"username":"test","password":"test"}' \
    --headers "Content-Type: application/json" || true

# 4. Secret detection
docker run --rm \
    -v $(pwd):/repo \
    trufflesecurity/trufflehog:latest \
    filesystem /repo

# 5. SAST scanning with Semgrep
docker run --rm \
    -v $(pwd):/src \
    -w /src \
    returntocorp/semgrep:latest \
    semgrep --config=p/csharp .
```

---

## Git Hooks Testing

### Pre-commit Hook Test
```bash
# Create a test file with a hardcoded secret
echo 'ClientSecret = "SuperSecretKey123"' >> test-secret.cs

# Stage the file
git add test-secret.cs

# Attempt commit (hook should warn about secrets)
git commit -m "test: checking pre-commit hook"

# You should see security warnings
# Clean up
git reset HEAD test-secret.cs
rm test-secret.cs
```

### Pre-push Hook Test
```bash
# Create a branch with a secret in a commit
git checkout -b test/secret-branch
echo 'password = "PlainTextPassword123"' > test-password.cs
git add test-password.cs
git commit -m "test: password check"

# Attempt to push (hook should block or warn)
git push origin test/secret-branch

# Note: May fail if actual remote history is checked
# Clean up
git checkout master
git branch -D test/secret-branch
git push origin --delete test/secret-branch 2>/dev/null || true
```

---

## Jenkins Pipeline Setup

### Prerequisites
- Jenkins server with Docker support
- Jenkins Git plugin
- Docker available on Jenkins agent

### Step 1: Create Jenkins Pipeline Job
```bash
# Via Jenkins UI:
# 1. Click "New Item"
# 2. Enter job name: "DevSecOpsApp"
# 3. Select "Pipeline"
# 4. Click "OK"
```

### Step 2: Configure Pipeline
```bash
# In Pipeline section:
# - Select "Pipeline script from SCM"
# - SCM: Git
# - Repository URL: https://github.com/mchatzinikolaou/DevSecOpsApp.git
# - Script path: Jenkinsfile
# - Save
```

### Step 3: Trigger Build
```bash
# Click "Build Now" button
# Or use Jenkins CLI:
# jenkins-cli build DevSecOpsApp -s http://localhost:8080
```

### Step 4: Monitor Build
- Go to build console output
- Watch stages execute sequentially
- View artifacts when complete

### Step 5: Review Reports
- Download reports from "Build Artifacts"
- Check `reports/SECURITY_REPORT.md` for summary
- Review individual tool outputs

---

## Troubleshooting

### Docker Build Fails
```bash
# Clear Docker cache and rebuild
docker build --no-cache -t devsecopsapp:latest -f Dockerfile .

# Check Docker daemon
docker ps  # Should list containers
```

### Application Won't Start
```bash
# Check logs
docker-compose logs devsecopsapp

# Verify port 8080 is not in use
lsof -i :8080  # macOS/Linux
netstat -ano | findstr :8080  # Windows

# Kill process using port
kill -9 <PID>  # macOS/Linux
taskkill /PID <PID> /F  # Windows
```

### Git Hooks Not Triggering
```bash
# Verify hooks path is set
git config core.hooksPath  # Should output: .husky

# Check hook file permissions
ls -la .husky/pre-commit  # Should have executable bit (x)

# Make executable if needed
chmod +x .husky/pre-commit
chmod +x .husky/pre-push
```

### Tool Docker Images Too Large
```bash
# Clean up unused images
docker image prune -f

# Remove specific tool images
docker rmi aquasec/trivy:latest
docker rmi ghcr.io/zaproxy/zaproxy:stable
```

### Network Issues in Docker
```bash
# Check Docker network
docker network ls

# Recreate network
docker network rm devsecops-network 2>/dev/null || true
docker-compose down
docker-compose up -d
```

---

## Expected Findings by Tool

| Tool | Expected Finding | Severity | Location |
|------|------------------|----------|----------|
| **dotnet list package** | Newtonsoft.Json 9.0.1 vulnerable | High | CVE Database |
| **Semgrep** | SQL injection in LoginController | Critical | Controllers/LoginController.cs:31 |
| **Semgrep** | Command injection in CommandController | Critical | Controllers/CommandController.cs:24 |
| **Semgrep** | Hardcoded secret | High | appsettings.json:9 |
| **TruffleHog** | ClientSecret in JSON | High | appsettings.json |
| **Trivy** | EOL .NET 5.0 runtime | Medium | Dockerfile base image |
| **Trivy** | OS package vulnerabilities | Medium-High | Ubuntu base packages |
| **OWASP ZAP** | Swagger endpoint exposure | Low | /swagger/index.html |
| **sqlmap** | SQL injection confirmed | Critical | /api/login |
| **Nmap** | Open port 8080 | Info | Port scan results |

---

## Performance Expectations

| Stage | Tool | Expected Time | Notes |
|-------|------|----------------|-------|
| Checkout | Git | ~5s | Quick, depends on network |
| Dependencies | dotnet | ~30s | Fast, checks local cache |
| SAST | Semgrep | ~60s | Depends on codebase size |
| Secrets | TruffleHog | ~30s | Scans all files |
| Build | Docker | ~2m | First run slower, cache helps |
| Container Scan | Trivy | ~60s | Depends on image size |
| Port Scan | Nmap | ~30s | Quick port enumeration |
| DAST | OWASP ZAP | ~3m | Comprehensive scanning |
| SQL Injection | sqlmap | ~2m | Algorithm-based testing |
| **Total Pipeline** | All | ~15-20m | End-to-end execution |

---

## Useful Commands Reference

### Docker Management
```bash
# Build image
docker build -t devsecopsapp:latest -f Dockerfile .

# List images
docker images | grep devsecopsapp

# Remove image
docker rmi devsecopsapp:latest

# Build and run with compose
docker-compose up -d --build
docker-compose down
docker-compose logs -f
```

### Testing Endpoints
```bash
# Health check
curl -s http://localhost:8080/swagger/index.html | head

# Weather endpoint
curl http://localhost:8080/WeatherForecast

# Login endpoint
curl -X POST http://localhost:8080/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test"}'

# Command endpoint
curl -X POST http://localhost:8080/api/command/execute \
  -H "Content-Type: application/json" \
  -d '{"command":"id"}'
```

### Security Scanning
```bash
# Check vulnerable packages
dotnet list package --vulnerable

# Run Semgrep
docker run --rm -v $(pwd):/src returntocorp/semgrep:latest \
    semgrep --config=p/csharp /src

# Scan container with Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy:latest image devsecopsapp:latest

# Run OWASP ZAP
docker run --rm --network host -v $(pwd)/reports:/zap/results \
    ghcr.io/zaproxy/zaproxy:stable \
    zap-baseline.py -t http://localhost:8080
```

---

## File Structure

```
DevSecOpsApp/
??? Controllers/
?   ??? WeatherForecastController.cs    (Safe endpoint)
?   ??? LoginController.cs               (SQL injection)
?   ??? CommandController.cs             (Command injection)
??? RequestObjects/
?   ??? WeatherForecast.cs
?   ??? LoginRequest.cs
?   ??? UserDataRequest.cs
?   ??? CustomCommandRequest.cs
?   ??? RoleTypeEnum.cs
??? .husky/
?   ??? pre-commit                       (Git hook - quick checks)
?   ??? pre-push                         (Git hook - extended checks)
??? appsettings.json                    (Hardcoded secrets)
??? Dockerfile                           (EOL .NET 5.0 base image)
??? docker-compose.yml                   (Application orchestration)
??? Jenkinsfile                          (CI/CD pipeline - 9 stages)
??? endpoints.txt                        (Endpoints for DAST)
??? .semgrep.yml                         (Semgrep configuration)
??? DOCUMENTATION.md                     (Comprehensive guide)
??? IMPLEMENTATION_STATUS.md             (Completion status)
??? SETUP_GUIDE.md                       (This file)
??? Program.cs                           (Application entry point)
??? DevSecOpsApp.csproj                  (Project file)
??? README.md                            (Basic overview)
```

---

## Next Steps

1. **Local Validation**
   - Run all steps in "Local Setup" section
   - Execute "Quick Scan" under security scans
   - Verify application responds

2. **Jenkins Setup**
   - Configure Jenkins pipeline (optional)
   - Execute Jenkinsfile locally or on server
   - Generate full reports

3. **Documentation**
   - Review DOCUMENTATION.md for detailed information
   - Check IMPLEMENTATION_STATUS.md for what's included
   - Review findings from security tools

4. **Final Submission**
   - Ensure Git repository is clean
   - Verify all files are committed
   - Push to GitHub
   - Prepare final technical report

---

## Support & Questions

- **Documentation**: See DOCUMENTATION.md for detailed information
- **Status**: See IMPLEMENTATION_STATUS.md for what's implemented
- **Issues**: Report via GitHub Issues
- **Repository**: https://github.com/mchatzinikolaou/DevSecOpsApp

---

**Last Updated**: $(date)
**Version**: 1.0
**Status**: Ready for Use
