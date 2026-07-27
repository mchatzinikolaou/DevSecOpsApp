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
                    
                    # 1. Dependency Scan
                    dotnet list package --vulnerable > ${REPORT_DIR}/dependencies.txt 2>&1 || true
                    
                    # 2. Semgrep (Code Analysis)
                    docker run --rm -v ${WORKSPACE}:/src -w /src returntocorp/semgrep:latest semgrep --config=p/csharp . > ${REPORT_DIR}/semgrep.txt 2>&1 || true
                    
                    # 3. TruffleHog (Secret Detection)
                    docker run --rm -v ${WORKSPACE}:/repo trufflesecurity/trufflehog:latest filesystem /repo > ${REPORT_DIR}/trufflehog.txt 2>&1 || true
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
                    # 1. Nmap (Port Scanning)
                    docker run --rm --network host networkstatic/nmap:latest nmap -sV -p- localhost > ${REPORT_DIR}/nmap.txt 2>&1 || true
                    
                    # 2. sqlmap (SQL Injection Testing)
                    docker run --rm --network host sqlmap/sqlmap:latest sqlmap.py --batch -u "http://localhost:8080/api/login" --method POST --data '{"Username":"admin", "Password":"password"}' --headers "Content-Type: application/json" > ${REPORT_DIR}/sqlmap.txt 2>&1 || true
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