# DevSecOpsApp - DevSecOps Pipeline

## Quick Start
\`\`\`bash
# Install git hooks
bash git-hooks/install-hooks.sh

# Run locally
dotnet run

# Run in Docker
docker-compose up
\`\`\`

## Pipeline
- **Git Hooks:** pre-commit (secrets), pre-push (build)
- **Jenkins:** Dependency scan → Semgrep → Build → Docker scan → Dynamic tests
- **Tools:** Semgrep, TruffleHog, sqlmap, Trivy

## Vulnerabilities (Intentional)
- Hardcoded secrets in appsettings.json
- SQL injection in /api/login
- Command injection in /api/command/execute
- Unhashed passwords

## Reports
Generated in `./reports/` after Jenkins run.