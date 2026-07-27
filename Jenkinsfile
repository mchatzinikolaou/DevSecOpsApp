pipeline {
    agent any

    options {
        timeout(time: 1, unit: 'HOURS')
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['Dev', 'Staging', 'Production'], description: 'Target environment')
    }

    environment {
        DOCKER_IMAGE_NAME = "devsecopsapp"
        DOCKER_IMAGE_TAG = "${BUILD_NUMBER}"
        REPORT_DIR = "${WORKSPACE}/reports"
    }

    stages {
        stage('Checkout') {
            steps {
                echo "Checking out code from Git repository..."
                checkout scm
            }
        }

        stage('Static Analysis - Dependency Scanning') {
            steps {
                script {
                    echo "Stage: Dependency Scanning with dotnet list package"
                    sh '''
                        mkdir -p ${REPORT_DIR}
                        
                        echo "=== Checking for vulnerable NuGet packages ==="
                        dotnet list package --vulnerable > ${REPORT_DIR}/dotnet-vulnerable-packages.txt 2>&1 || true
                        
                        echo "=== Full package list for SCA ==="
                        dotnet list package > ${REPORT_DIR}/dotnet-packages-list.txt 2>&1 || true
                        
                        cat ${REPORT_DIR}/dotnet-vulnerable-packages.txt
                    '''
                }
            }
        }

        stage('Static Analysis - SAST with Semgrep') {
            steps {
                script {
                    echo "Stage: Running Semgrep for C# SAST..."
                    sh '''
                        mkdir -p ${REPORT_DIR}
                        
                        # Run Semgrep in Docker
                        docker run --rm \
                            -v ${WORKSPACE}:/src \
                            -w /src \
                            returntocorp/semgrep:latest \
                            semgrep --config=p/csharp --json --output=${REPORT_DIR}/semgrep-findings.json . || true
                        
                        # Also run with human-readable output
                        docker run --rm \
                            -v ${WORKSPACE}:/src \
                            -w /src \
                            returntocorp/semgrep:latest \
                            semgrep --config=p/csharp . > ${REPORT_DIR}/semgrep-findings.txt 2>&1 || true
                        
                        cat ${REPORT_DIR}/semgrep-findings.txt
                    '''
                }
            }
        }

        stage('Static Analysis - Secret Detection') {
            steps {
                script {
                    echo "Stage: Running TruffleHog for secrets detection..."
                    sh '''
                        mkdir -p ${REPORT_DIR}
                        
                        # Run TruffleHog in Docker
                        docker run --rm \
                            -v ${WORKSPACE}:/repo \
                            trufflesecurity/trufflehog:latest \
                            filesystem /repo \
                            --json > ${REPORT_DIR}/trufflehog-findings.json 2>&1 || true
                        
                        # Create human-readable report
                        docker run --rm \
                            -v ${WORKSPACE}:/repo \
                            trufflesecurity/trufflehog:latest \
                            filesystem /repo \
                            > ${REPORT_DIR}/trufflehog-findings.txt 2>&1 || true
                        
                        cat ${REPORT_DIR}/trufflehog-findings.txt
                    '''
                }
            }
        }

        stage('Build Application') {
            steps {
                script {
                    echo "Stage: Building .NET application and Docker image..."
                    sh '''
                        # Build the Docker image
                        docker build -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} \
                                     -t ${DOCKER_IMAGE_NAME}:latest \
                                     -f Dockerfile .
                        
                        echo " Docker image built successfully: ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
                    '''
                }
            }
        }

        stage('Dynamic Analysis - Container Scanning with Trivy') {
            steps {
                script {
                    echo "Stage: Scanning Docker image for vulnerabilities with Trivy..."
                    sh '''
                        mkdir -p ${REPORT_DIR}
                        
                        # Scan Docker image with Trivy
                        docker run --rm \
                            -v /var/run/docker.sock:/var/run/docker.sock \
                            aquasec/trivy:latest \
                            image \
                            --severity HIGH,CRITICAL \
                            --format json \
                            ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} > ${REPORT_DIR}/trivy-image-findings.json 2>&1 || true
                        
                        # Human-readable report
                        docker run --rm \
                            -v /var/run/docker.sock:/var/run/docker.sock \
                            aquasec/trivy:latest \
                            image \
                            --severity HIGH,CRITICAL \
                            ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} > ${REPORT_DIR}/trivy-image-findings.txt 2>&1 || true
                        
                        echo "=== Trivy Container Scan Results ==="
                        cat ${REPORT_DIR}/trivy-image-findings.txt
                    '''
                }
            }
        }

        stage('Dynamic Analysis - Start Application') {
            steps {
                script {
                    echo "Stage: Starting application container..."
                    sh '''
                        # Clean up any existing containers
                        docker-compose down || true
                        
                        # Start the application
                        docker-compose up -d
                        
                        # Wait for the application to be ready
                        echo "Waiting for application to start..."
                        for i in {1..30}; do
                            if curl -s http://localhost:8080/swagger/index.html > /dev/null; then
                                echo "Application is ready"
                                break
                            fi
                            echo "  Attempt $i/30: Waiting for application..."
                            sleep 2
                        done
                    '''
                }
            }
        }

        stage('Dynamic Analysis - Port Scanning with Nmap') {
            steps {
                script {
                    echo "Stage: Running Nmap port scan..."
                    sh '''
                        mkdir -p ${REPORT_DIR}
                        
                        # Port scanning
                        docker run --rm \
                            --network host \
                            networkstatic/nmap:latest \
                            nmap -sV -p- localhost > ${REPORT_DIR}/nmap-findings.txt 2>&1 || true
                        
                        echo "=== Nmap Port Scan Results ==="
                        cat ${REPORT_DIR}/nmap-findings.txt
                    '''
                }
            }
        }

        stage('Dynamic Analysis - DAST with OWASP ZAP') {
            steps {
                script {
                    echo "Stage: Running OWASP ZAP for DAST..."
                    sh '''
                        mkdir -p ${REPORT_DIR}
                        
                        # Create ZAP configuration script
                        cat > ${REPORT_DIR}/zap-script.sh << 'EOF'
#!/bin/bash
# ZAP scanning script

ZAP_HOME=/zap

# Start ZAP in daemon mode
$ZAP_HOME/zap.sh -cmd \
    -quickurl http://localhost:8080/swagger/index.html \
    -quickout /zap/results.html &

# Wait for scan to complete
sleep 30

# Kill ZAP
pkill -f "zap.sh"
EOF
                        chmod +x ${REPORT_DIR}/zap-script.sh
                        
                        # Run OWASP ZAP
                        docker run --rm \
                            --network host \
                            -v ${REPORT_DIR}:/zap/results \
                            -t ghcr.io/zaproxy/zaproxy:stable \
                            zap-baseline.py \
                            -t http://localhost:8080 \
                            -J ${REPORT_DIR}/zap-findings.json \
                            -r ${REPORT_DIR}/zap-findings.html \
                            || true
                        
                        echo "OWASP ZAP scan completed"
                    '''
                }
            }
        }

        stage('Dynamic Analysis - SQL Injection Testing') {
            steps {
                script {
                    echo "Stage: Testing for SQL injection vulnerabilities..."
                    sh '''
                        mkdir -p ${REPORT_DIR}
                        
                        # Test SQL Injection on login endpoint
                        echo "=== SQL Injection Test Results ===" > ${REPORT_DIR}/sqlmap-findings.txt
                        
                        docker run --rm \
                            --network host \
                            sqlmap/sqlmap:latest \
                            sqlmap.py \
                            --batch \
                            -u "http://localhost:8080/api/login" \
                            --method POST \
                            --data '{"username":"test","password":"test"}' \
                            --headers "Content-Type: application/json" \
                            -o \
                            --json-report=${REPORT_DIR}/sqlmap-report.json \
                            >> ${REPORT_DIR}/sqlmap-findings.txt 2>&1 || true
                        
                        echo "SQL Injection testing completed"
                        cat ${REPORT_DIR}/sqlmap-findings.txt
                    '''
                }
            }
        }

        stage('Cleanup') {
            steps {
                script {
                    echo "Stage: Cleaning up containers..."
                    sh '''
                        docker-compose down || true
                        echo "Cleanup completed"
                    '''
                }
            }
        }

        stage('Generate Report') {
            steps {
                script {
                    echo "Stage: Generating summary report..."
                    sh '''
                        mkdir -p ${REPORT_DIR}
                        
                        # Create comprehensive report
                        cat > ${REPORT_DIR}/SECURITY_REPORT.md << 'EOF'
# DevSecOpsApp Security Assessment Report
**Build ID:** ${BUILD_NUMBER}
**Build Date:** $(date)
**Branch:** ${GIT_BRANCH}
**Commit:** ${GIT_COMMIT}

## Summary

This report contains the results of automated security scanning performed during the CI/CD pipeline.

### Scan Categories

1. **Dependency Scanning** - Detection of vulnerable NuGet packages
2. **Static Analysis (SAST)** - Code-level vulnerability detection with Semgrep
3. **Secret Detection** - Hardcoded credentials and sensitive data detection with TruffleHog
4. **Container Scanning** - Docker image vulnerability scanning with Trivy
5. **Port Scanning** - Open ports and services detection with Nmap
6. **Dynamic Testing (DAST)** - Web application scanning with OWASP ZAP
7. **SQL Injection Testing** - Specific SQL injection vulnerability testing with sqlmap

## Detailed Results

### 1. Dependency Scanning
See: `dotnet-vulnerable-packages.txt`

### 2. SAST Findings
See: `semgrep-findings.json` and `semgrep-findings.txt`

### 3. Secret Detection
See: `trufflehog-findings.json` and `trufflehog-findings.txt`

### 4. Container Vulnerabilities
See: `trivy-image-findings.json` and `trivy-image-findings.txt`

### 5. Port Scan Results
See: `nmap-findings.txt`

### 6. Web Application Scan
See: `zap-findings.json` and `zap-findings.html`

### 7. SQL Injection Test Results
See: `sqlmap-findings.txt` and `sqlmap-report.json`

## Known Intentional Vulnerabilities

The following vulnerabilities are **intentionally introduced** for testing purposes:

1. **SQL Injection in /api/login** - Login endpoint uses string concatenation for SQL queries
2. **Command Injection in /api/command/execute** - Command execution endpoint passes user input directly to Process.Start
3. **Hardcoded Secrets** - ClientSecret exposed in appsettings.json
4. **Vulnerable Dependency** - Newtonsoft.Json v9.0.1 (contains known CVEs)
5. **Outdated Base Image** - Docker image based on .NET 5.0 (EOL)

## Recommendations

1. Use parameterized queries instead of string concatenation
2. Validate and sanitize user input before executing system commands
3. Move secrets to secure configuration management (Azure Key Vault, HashiCorp Vault)
4. Update all NuGet packages to latest secure versions
5. Use current .NET versions and regularly update base images
6. Implement input validation and output encoding
7. Apply principle of least privilege to application permissions

## Artifacts

All detailed reports and logs are available in the reports directory.
EOF
                        
                        echo "Summary report generated"
                        cat ${REPORT_DIR}/SECURITY_REPORT.md
                    '''
                }
            }
        }
    }

    post {
        always {
            script {
                echo "Post-build: Archiving reports and cleaning up..."
                
                // Archive all reports
                archiveArtifacts artifacts: 'reports/**/*', 
                                 allowEmptyArchive: true
                
                // Attempt cleanup
                sh '''
                    docker-compose down || true
                    docker image prune -f --filter "dangling=true" || true
                '''
            }
        }
        success {
            echo "Build and security scan completed"
        }
        failure {
            echo "Build or security scan failed - review reports"
        }
    }
}
