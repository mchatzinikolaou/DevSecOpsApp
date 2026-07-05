# 🚀 QUICK REFERENCE - DevSecOpsApp

## IN 30 SECONDS

✅ **What**: ASP.NET Core 8.0 web app with intentional security vulnerabilities  
✅ **Purpose**: DevSecOps pipeline demonstration with automated security scanning  
✅ **Status**: 85-90% complete, ready for testing  
✅ **Repo**: https://github.com/mchatzinikolaou/DevSecOpsApp  

## IN 5 MINUTES

```bash
# Clone
git clone https://github.com/mchatzinikolaou/DevSecOpsApp.git
cd DevSecOpsApp

# Build & Run
docker build -t devsecopsapp:latest -f Dockerfile .
docker-compose up -d

# Test
curl http://localhost:8080/swagger/index.html
```

## THE QUICK FACTS

| What | Count |
|------|-------|
| **Vulnerabilities** | 5 (SQL Injection, Command Injection, Hardcoded Secrets, etc.) |
| **Security Tools** | 7 (Semgrep, TruffleHog, Trivy, OWASP ZAP, Nmap, sqlmap, dotnet) |
| **CI/CD Stages** | 11 |
| **Git Hooks** | 2 (pre-commit, pre-push) |
| **Docker Images** | 1 app + 7 tool images |
| **Endpoints** | 3 (Weather, Login, Command) |

## THE 5 VULNERABILITIES

| # | Type | Where | Payload |
|---|------|-------|---------|
| 1 | SQL Injection | `POST /api/login` | `admin' OR '1'='1` |
| 2 | Command Injection | `POST /api/command/execute` | `cat /etc/passwd` |
| 3 | Hardcoded Secret | `appsettings.json` | `ClientSecret = "..."` |
| 4 | Vulnerable Package | `DevSecOpsApp.csproj` | `Newtonsoft.Json 9.0.1` |
| 5 | EOL Base Image | `Dockerfile` | `.NET 5.0` |

## THE 7 SECURITY TOOLS

### Static Analysis (Find before running)
- **Semgrep**: Finds injection attacks and secrets in code
- **TruffleHog**: Finds exposed credentials
- **dotnet list**: Finds vulnerable dependencies

### Dynamic Analysis (Find while running)
- **Trivy**: Scans Docker image for vulnerabilities
- **OWASP ZAP**: Scans running web app
- **Nmap**: Finds open ports and services
- **sqlmap**: Tests for SQL injection

## THE 11 PIPELINE STAGES

```
1. Checkout          → Get code from Git
2. Dep Scan          → Find bad packages (dotnet)
3. SAST              → Find bad code (Semgrep)
4. Secrets           → Find exposed credentials (TruffleHog)
5. Build             → Create Docker image
6. Container Scan    → Scan image (Trivy)
7. Start App         → Run the application
8. Port Scan         → Find open ports (Nmap)
9. Web Scan          → Scan web app (OWASP ZAP)
10. SQL Injection    → Test SQL injection (sqlmap)
11. Cleanup & Report → Generate summary
```

## COMMANDS TO TRY

### Local Testing
```bash
# Build & run
docker build -t devsecopsapp:latest -f Dockerfile .
docker-compose up -d

# Test SQL injection
curl -X POST http://localhost:8080/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin'"'"' OR '"'"'1'"'"'='"'"'1","password":"x"}'

# Test command injection
curl -X POST http://localhost:8080/api/command/execute \
  -H "Content-Type: application/json" \
  -d '{"command":"id"}'

# Stop
docker-compose down
```

### Security Scanning
```bash
# Check vulnerabilities
dotnet list package --vulnerable

# Scan image
docker run --rm aquasec/trivy:latest image devsecopsapp:latest

# Find secrets
docker run --rm -v $(pwd):/repo \
  trufflesecurity/trufflehog:latest filesystem /repo

# Run SAST
docker run --rm -v $(pwd):/src returntocorp/semgrep:latest \
  semgrep --config=p/csharp /src
```

### Git Hooks
```bash
# Install
git config core.hooksPath .husky
chmod +x .husky/pre-commit .husky/pre-push

# Test
git commit -m "test"  # Runs pre-commit hook
git push origin       # Runs pre-push hook
```

### Jenkins Pipeline
```groovy
// Jenkins → New Item → Pipeline
// Repository: https://github.com/mchatzinikolaou/DevSecOpsApp
// Script Path: Jenkinsfile
// Build!
```

## FILES TO KNOW

| File | Purpose | Important |
|------|---------|-----------|
| `Jenkinsfile` | CI/CD pipeline | ⭐ |
| `Dockerfile` | Container definition | ⭐ |
| `docker-compose.yml` | Orchestration | ⭐ |
| `Controllers/LoginController.cs` | SQL Injection | ⚠️ |
| `Controllers/CommandController.cs` | Command Injection | ⚠️ |
| `appsettings.json` | Hardcoded secret | ⚠️ |
| `.husky/pre-commit` | Git hook | 🔧 |
| `.husky/pre-push` | Git hook | 🔧 |
| `.semgrep.yml` | SAST config | 🔧 |
| `endpoints.txt` | DAST targets | 🔧 |

## COMPLIANCE

✅ **OWASP Top 10** - Injection, Broken Auth, Data Exposure  
✅ **CWE Coverage** - CWE-89 (SQL), CWE-78 (Command), CWE-798 (Secrets)  
✅ **DevSecOps** - Shift-left, automation, continuous scanning  
✅ **Best Practices** - IaC, pipeline as code, reproducible  

## TYPICAL FINDINGS

**Expected to be found**:
- SQL injection via username parameter
- Command injection via command parameter
- Hardcoded ClientSecret in config
- Newtonsoft.Json 9.0.1 vulnerable package
- .NET 5.0 EOL runtime
- Port 8080 open with service