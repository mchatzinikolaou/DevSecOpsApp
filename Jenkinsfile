pipeline {
    agent any

    environment {
        REPORT_DIR = "${WORKSPACE}/reports"
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '5'))
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Static Analysis (SAST)') {
            steps {
                echo "Running 3 required static checks..."
                sh '''
                    mkdir -p ${REPORT_DIR}

                    # 1. Dependency Scan (using Docker with .NET SDK) - specify the project file
                    docker run --rm -v ${WORKSPACE}:/app -w /app mcr.microsoft.com/dotnet/sdk:8.0 dotnet list DevSecOpsApp.csproj package --vulnerable --include-transitive > ${REPORT_DIR}/dependencies.txt 2>&1 || true

                    # 2. Semgrep (Code Analysis) - scan C# files with proper patterns
                    docker run --rm -v ${WORKSPACE}:/src returntocorp/semgrep:latest semgrep --config=p/csharp --config=p/security-audit --config=p/owasp-top-ten /src --include="*.cs" --exclude=".vs" --exclude="obj" --exclude="bin" --exclude="temp" --json > ${REPORT_DIR}/semgrep.json 2>&1 || true
                    docker run --rm -v ${WORKSPACE}:/src returntocorp/semgrep:latest semgrep --config=p/csharp --config=p/security-audit --config=p/owasp-top-ten /src --include="*.cs" --exclude=".vs" --exclude="obj" --exclude="bin" --exclude="temp" > ${REPORT_DIR}/semgrep.txt 2>&1 || true

                    # 3. TruffleHog (Secret Detection) - scan git repo
                    docker run --rm -v ${WORKSPACE}/.git:/repo/.git:ro -v ${WORKSPACE}:/repo:ro -w /repo trufflesecurity/trufflehog:latest git file://. --json > ${REPORT_DIR}/trufflehog.json 2>&1 || true
                    docker run --rm -v ${WORKSPACE}/.git:/repo/.git:ro -v ${WORKSPACE}:/repo:ro -w /repo trufflesecurity/trufflehog:latest git file://. > ${REPORT_DIR}/trufflehog.txt 2>&1 || true
                '''
            }
        }

        stage('Build & Run Application') {
            steps {
                echo "Building and spinning up the environment..."
                sh '''
                    docker-compose down || true
                    docker-compose up -d --build
                    sleep 15
                '''
            }
        }

        stage('Dynamic Analysis (DAST)') {
            steps {
                echo "Running 2 required dynamic checks against the live container..."
                sh '''
                    # Wait for application to be fully ready
                    sleep 5

                    # 1. Nmap (Port Scanning) - scan the container via docker network
                    docker run --rm --network devsecops-network instrumentisto/nmap:latest -sV -p 8080 devsecopsapp > ${REPORT_DIR}/nmap.txt 2>&1 || true

                    # 2. sqlmap (SQL Injection Testing) - test login endpoint with POST
                    docker run --rm --network devsecops-network secsi/sqlmap:latest sqlmap.py --batch --flush-session -u "http://devsecopsapp:8080/api/login" --method POST --data='{"Username":"admin","Password":"password"}' --headers="Content-Type: application/json" --risk=3 --level=5 --random-agent --dbms=SQLite > ${REPORT_DIR}/sqlmap.txt 2>&1 || true
                '''
            }
        }
    }

    post {
        always {
            echo "Archiving reports and tearing down containers..."
            archiveArtifacts artifacts: 'reports/*', allowEmptyArchive: true
            
            sh 'docker-compose down || true'
        }
        success {
            echo "Pipeline completed successfully!"
        }
        failure {
            echo "Pipeline failed. Check the logs."
        }
    }
}