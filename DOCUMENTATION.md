# DevSecOpsApp - Complete Project Documentation

## Project Overview

**DevSecOpsApp** is an ASP.NET Core 8.0 Web API application designed to demonstrate DevSecOps practices and automated security pipeline implementation. The project includes intentionally introduced security vulnerabilities for educational purposes and a comprehensive automated testing pipeline.

## Technology Stack

- **Framework**: ASP.NET Core 8.0
- **Language**: C# 12.0
- **Container**: Docker (multi-stage build)
- **CI/CD**: Jenkins
- **Git Hooks**: Bash scripts (compatible with Husky.Net)
- **Database**: SQLite (in-memory for development)

## Intentionally Introduced Vulnerabilities

### 1. SQL Injection (Critical)
- **Location**: `Controllers/LoginController.cs`
- **Vulnerability**: String concatenation in SQL query
- **Code**:
  ```csharp
  string query = $"SELECT Password FROM Users WHERE Username = '{model.Username}'";
  ```
- **Attack Vector**: `/api/login` endpoint
- **Example Payload**: `{"username": "admin' OR '1'='1", "password": "anything"}`

### 2. Command Injection (Critical)
- **Location**: `Controllers/CommandController.cs`
- **Vulnerability**: Direct execution of user-provided commands
- **Code**:
  ```csharp
  var processInfo = new ProcessStartInfo
  {
      FileName = "/bin/bash",
      Arguments = $"-c \"{request.Command}\"",
      ...
  };
  ```
- **Attack Vector**: `/api/command/execute` endpoint
- **Example Payload**: `{"command": "cat /etc/passwd"}`

### 3. Hardcoded Secrets (High)
- **Location**: `appsettings.json`
- **Secret**: `ClientSecret = "PlaintextSecretAlbeitComplicated!@#!1233.-"`
- **Type**: Plaintext configuration secret
- **Detection**: TruffleHog, Semgrep

### 4. Vulnerable Dependency (High)
- **Package**: Newtonsoft.Json v9.0.1
- **CVEs**: CVE-2017-9731, CVE-2019-0604
- **Reason**: Outdated version with known security issues
- **Detection**: `dotnet list package --vulnerable`

### 5. Outdated Base Image (Medium)
- **Location**: `Dockerfile`
- **Base Image**: `mcr.microsoft.com/dotnet/aspnet:5.0`
- **Status**: End-of-Life (EOL)
- **Detection**: Trivy container scanning

## Git Workflow and Hooks

### Pre-commit Hook (`.husky/pre-commit`)
**Purpose**: Quick local checks before committing

**Checks performed**:
1. Pattern-based secret detection
2. Suspicious code patterns (Process.Start, SQL concatenation)
3. Code formatting verification (if dotnet format installed)

**Trigger**: Automatically when running `git commit`

**Decision**: Warnings only (non-blocking) to allow flexibility in development

### Pre-push Hook (`.husky/pre-push`)
**Purpose**: Extended checks before pushing to remote

**Checks performed**:
1. Credential pattern detection in commit diffs
2. Verification against remote history

**Trigger**: Automatically when running `git push origin`

**Decision**: Blocking on critical issues (secrets detected)

### Installation
```bash
# Install git hooks locally
git config core.hooksPath .husky
chmod +x .husky/pre-commit
chmod +x .husky/pre-push
```

## CI/CD Pipeline Architecture

### Pipeline Overview
The Jenkins pipeline (`Jenkinsfile`) implements a comprehensive DevSecOps workflow with 9 stages:

```
Checkout 
  ?
Static Analysis (Dependency Scanning)
  ?
Static Analysis (SAST with Semgrep)
  ?
Static Analysis (Secret Detection)
  ?
Build (Docker Image)
  ?
Dynamic Analysis (Container Scanning)
  ?
Dynamic Analysis (Start Application)
  ?
Dynamic Analysis (Port Scanning)
  ?
Dynamic Analysis (DAST)
  ?
Dynamic Analysis (SQL Injection Testing)
  ?
Cleanup & Report Generation
```

### Stage Details

#### 1. Checkout
- **Tool**: Jenkins Git plugin
- **Purpose**: Clone repository code
- **Time**: ~5 seconds

#### 2. Static Analysis - Dependency Scanning
- **Tool**: `dotnet list package --vulnerable`
- **Purpose**: Identify vulnerable NuGet packages
- **Output**: `dotnet-vulnerable-packages.txt`
- **Time**: ~30 seconds

#### 3. Static Analysis - SAST
- **Tool**: Semgrep (via Docker)
- **Purpose**: Code-level vulnerability detection
- **Configuration**: `.semgrep.yml`
- **Output**: `semgrep-findings.json`, `semgrep-findings.txt`
- **Time**: ~1 minute
- **Detects**: SQL injection, command injection, hardcoded secrets

#### 4. Static Analysis - Secret Detection
- **Tool**: TruffleHog (via Docker)
- **Purpose**: Scan for exposed credentials and API keys
- **Output**: `trufflehog-findings.json`, `trufflehog-findings.txt`
- **Time**: ~30 seconds

#### 5. Build Application
- **Tool**: Docker
- **Purpose**: Build Docker image from Dockerfile
- **Command**: `docker build -t devsecopsapp:${BUILD_NUMBER}`
- **Time**: ~2 minutes (depends on layer cache)

#### 6. Dynamic Analysis - Container Scanning
- **Tool**: Trivy (via Docker)
- **Purpose**: Scan built image for known vulnerabilities
- **Targets**: OS packages, .NET packages
- **Output**: `trivy-image-findings.json`, `trivy-image-findings.txt`
- **Time**: ~1 minute

#### 7. Start Application
- **Tool**: Docker Compose
- **Purpose**: Run application container for dynamic testing
- **Command**: `docker-compose up -d`
- **Wait Logic**: Waits up to 60 seconds for /swagger to be ready
- **Time**: ~10 seconds

#### 8. Dynamic Analysis - Port Scanning
- **Tool**: Nmap (via Docker)
- **Purpose**: Identify open ports and services
- **Target**: localhost
- **Output**: `nmap-findings.txt`
- **Time**: ~30 seconds

#### 9. Dynamic Analysis - DAST
- **Tool**: OWASP ZAP (via Docker)
- **Purpose**: Web application security scanning
- **Endpoints**: All discovered via Swagger endpoint
- **Output**: `zap-findings.json`, `zap-findings.html`
- **Time**: ~2-3 minutes

#### 10. Dynamic Analysis - SQL Injection Testing
- **Tool**: sqlmap (via Docker)
- **Purpose**: Specific SQL injection vulnerability testing
- **Endpoint**: `POST /api/login`
- **Output**: `sqlmap-findings.txt`, `sqlmap-report.json`
- **Time**: ~1-2 minutes

#### 11. Cleanup & Report
- **Purpose**: Stop containers, generate summary report
- **Output**: `SECURITY_REPORT.md`
- **Artifacts**: All reports archived in Jenkins

### Pipeline Configuration

**Total Execution Time**: ~15-20 minutes (depending on Docker layer caching)

**Requirements**:
- Docker and Docker Compose installed
- Jenkins with Docker support
- ~4GB RAM minimum
- ~20GB disk space for Docker images

## Tool Justification

| Tool | Category | Purpose | Why Chosen |
|------|----------|---------|-----------|
| **dotnet list package** | Dependency Scanning | NuGet vulnerability check | Built-in, no external dependencies |
| **Semgrep** | SAST | Code security analysis | Fast, excellent C# support, Docker-based |
| **TruffleHog** | Secret Detection | Credential scanning | Industry standard, low false positives |
| **Trivy** | Container Scanning | Image vulnerability scan | Comprehensive, fast, accurate CVE database |
| **Nmap** | Port Scanning | Service enumeration | Industry standard, detailed reporting |
| **OWASP ZAP** | DAST | Web app scanning | Comprehensive, automation-friendly |
| **sqlmap** | SQL Injection Testing | Injection vulnerability testing | Specialized tool, high accuracy |

## API Endpoints

### Weather Forecast (Safe)
```
GET /WeatherForecast
Returns: Array of weather forecast objects
```

### Login (SQL Injection Vulnerable)
```
POST /api/login
Body: {"username": "string", "password": "string"}
Returns: {"Message": "Login successful", "Token": "guid"}
Vulnerable: Username field (SQL Injection)
```

### Command Execution (Command Injection Vulnerable)
```
POST /api/command/execute
Body: {"command": "string"}
Returns: {"Output": "string", "Error": "string"}
Vulnerable: Command field (Command Injection)
```

### Swagger UI
```
GET /swagger/index.html
Returns: Interactive API documentation
```

## Endpoints for Dynamic Testing

See `endpoints.txt` for complete list of endpoints and example payloads.

**Key targets for DAST**:
- `/api/login` - SQL Injection
- `/api/command/execute` - Command Injection
- `/swagger/index.html` - General web security

## Running the Pipeline Locally

### Prerequisites
```bash
# Install Docker and Docker Compose
docker --version
docker-compose --version

# Install .NET 8 SDK
dotnet --version

# Install Jenkins (optional, can run docker-based)
```

### Quick Start

1. **Clone repository**:
   ```bash
   git clone https://github.com/mchatzinikolaou/DevSecOpsApp.git
   cd DevSecOpsApp
   ```

2. **Setup Git hooks**:
   ```bash
   git config core.hooksPath .husky
   chmod +x .husky/pre-commit .husky/pre-push
   ```

3. **Build application**:
   ```bash
   docker build -t devsecopsapp:latest -f Dockerfile .
   ```

4. **Run application**:
   ```bash
   docker-compose up -d
   ```

5. **Access application**:
   ```bash
   # Swagger UI
   http://localhost:8080/swagger/index.html
   
   # Weather Forecast
   curl http://localhost:8080/WeatherForecast
   ```

6. **Run security tests locally**:
   ```bash
   # Dependency scan
   dotnet list package --vulnerable
   
   # Container scan
   docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
       aquasec/trivy:latest image devsecopsapp:latest
   
   # Port scan
   docker run --rm --network host networkstatic/nmap:latest \
       nmap -sV -p- localhost
   ```

7. **Cleanup**:
   ```bash
   docker-compose down
   ```

### Running Jenkins Pipeline

1. **Create Jenkins job**:
   - Create new Pipeline job
   - Pipeline script from SCM
   - Repository URL: https://github.com/mchatzinikolaou/DevSecOpsApp
   - Script path: `Jenkinsfile`

2. **Configure Jenkins agents**:
   - Ensure Docker is available on build agent
   - Ensure sufficient disk space (~20GB)

3. **Trigger build**:
   - Manual trigger or GitHub webhook

4. **Review reports**:
   - Navigate to build artifacts
   - Download and review security reports

## Expected Findings

### Vulnerabilities Expected to be Detected

| Vulnerability | Tool | Expected | Status |
|---|---|---|---|
| SQL Injection | Semgrep, sqlmap | Yes | ? |
| Command Injection | Semgrep | Yes | ? |
| Hardcoded Secret (ClientSecret) | TruffleHog | Yes | ? |
| Vulnerable Newtonsoft.Json | dotnet list package | Yes | ? |
| EOL .NET 5.0 Base Image | Trivy | Yes | ? |
| Open Port 8080 | Nmap | Yes | ? |
| Swagger Endpoint Exposure | OWASP ZAP | Yes | ? |

### Expected False Positives
- Comments mentioning "password", "secret" in code
- Documentation references to vulnerabilities
- Example payloads in endpoints.txt

## Security Remediation

### Recommended Fixes

**1. Fix SQL Injection**:
```csharp
// Before (Vulnerable)
string query = $"SELECT Password FROM Users WHERE Username = '{model.Username}'";

// After (Secure)
string query = "SELECT Password FROM Users WHERE Username = @username";
using var command = new SqliteCommand(query, connection);
command.Parameters.AddWithValue("@username", model.Username);
```

**2. Fix Command Injection**:
```csharp
// Before (Vulnerable)
var processInfo = new ProcessStartInfo { Arguments = $"-c \"{request.Command}\"" };

// After (Secure - use allowlist)
var allowedCommands = new[] { "ping", "whoami", "ls" };
if (!allowedCommands.Contains(request.Command.Split()[0]))
    throw new InvalidOperationException("Command not allowed");
```

**3. Fix Hardcoded Secrets**:
```json
// Move to environment variables or secure vault
"ClientSecret": "${AZURE_CLIENT_SECRET}"
```

**4. Update Vulnerable Dependencies**:
```bash
dotnet package update --highest-minor
# Update Newtonsoft.Json to latest version
```

**5. Update Base Image**:
```dockerfile
# Before: mcr.microsoft.com/dotnet/aspnet:5.0
# After: mcr.microsoft.com/dotnet/aspnet:8.0
```

## Limitations and Considerations

### Current Limitations

1. **DAST Coverage**: OWASP ZAP may miss endpoints that require authentication
   - Recommendation: Add authenticated scanning variant

2. **False Negatives**: sqlmap requires application to be running
   - Recommendation: Add timeout handling for slow responses

3. **Dependency Scanning**: Only checks direct NuGet packages
   - Recommendation: Enable transitive dependency scanning with Snyk

4. **Database Initialization**: SQL injection tests require initialized database
   - Recommendation: Add automated database seeding in pipeline

5. **Container Image Size**: Scanning adds ~500MB to build time
   - Recommendation: Use container layer caching aggressively

### Platform-Specific Notes

- **Windows Hosts**: Shell-based hooks may not work; use PowerShell variants
- **CI/CD Environment**: Jenkins may need additional Docker socket permissions
- **Network**: Ensure firewall allows localhost:8080 access during testing

## Compliance and Standards

This project demonstrates compliance with:

- **OWASP Top 10**: Addresses injection, broken authentication
- **CWE Coverage**: Covers CWE-89 (SQL Injection), CWE-78 (Command Injection)
- **NIST Cybersecurity Framework**: Identify, Protect, Detect principles
- **ISO 27001**: Security assessment and control implementation

## Future Enhancements

1. **Integration Testing**: Add functional test coverage
2. **Performance Testing**: Add load testing and memory profiling
3. **SBOM Generation**: Create Software Bill of Materials with Syft
4. **Policy Enforcement**: Add OPA (Open Policy Agent) for security policies
5. **Artifact Signing**: Sign build artifacts with cosign
6. **Supply Chain Security**: Add SLSA provenance tracking

## References

- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)
- [CWE Top 25](https://cwe.mitre.org/top25/)
- [Semgrep Rules](https://semgrep.dev/r)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [OWASP ZAP](https://www.zaproxy.org/)

## License and Disclaimer

This project is for **educational purposes only**. The intentionally introduced vulnerabilities are designed for learning and testing security tools in a controlled environment. 

**IMPORTANT**: 
- Do not deploy this application in production
- Do not run security tests against systems you do not own or have permission to test
- Only use in isolated, authorized testing environments

## Contact and Support

For questions or issues:
- Repository: https://github.com/mchatzinikolaou/DevSecOpsApp
- Issues: GitHub Issues
- Branch: master
