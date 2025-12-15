pipeline {
    agent any
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '20'))
        disableConcurrentBuilds()
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo "=== Tag Pipeline: Checkout ==="
                echo "Building version: ${env.TAG_NAME}"
                checkout scm
            }
        }
        
        stage('Setup') {
            steps {
                echo "=== Tag Pipeline: Setup ==="
                bat 'npm ci --prefer-offline'
            }
        }
        
        stage('Build') {
            steps {
                echo "=== Tag Pipeline: Build ==="
                bat 'npm run build'
                echo "✓ Release ${env.TAG_NAME} built successfully"
            }
        }
        
        stage('Run Docker') {
            steps {
                script {
                    echo "=== Tag Pipeline: Run Docker ==="
                    def tag = env.TAG_NAME
                    def imageName = "react:${tag}"
                    def containerName = "react_release_${tag.replace('.', '_')}"
                    
                    // Cleanup port 8080
                    bat """
                        @echo off
                        echo Cleaning port 8080 for release build...
                        for /f "tokens=*" %%i in ('docker ps --format "{{.Names}}"') do (
                            docker port %%i 2^>nul | findstr ":8080" >nul
                            if !errorlevel! == 0 (
                                docker stop %%i 2^>nul
                                docker rm -f %%i 2^>nul
                            )
                        )
                        
                        for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":8080 " ^| findstr "LISTENING" 2^>nul') do (
                            taskkill /F /PID %%p 2>nul
                        )
                        
                        docker rm -f ${containerName} 2>nul || exit 0
                        timeout /t 2 /nobreak
                        exit 0
                    """
                    
                    // Build production image
                    bat "docker rmi ${imageName} 2>nul || exit 0"
                    bat "docker build --no-cache -t ${imageName} ."
                    
                    // Run container
                    bat "docker run -d -p 8080:80 --name ${containerName} ${imageName}"
                    bat 'ping 127.0.0.1 -n 6 > nul'
                    
                    echo "✓ Release ${tag} running at http://localhost:8080"
                }
            }
        }
        
        stage('Smoke Test') {
            steps {
                echo "=== Tag Pipeline: Smoke Test ==="
                bat 'call smoke-test.bat http://localhost:8080'
                archiveArtifacts artifacts: 'smoke.log', allowEmptyArchive: true
            }
        }
        
        stage('Archive Artifacts') {
            steps {
                echo "=== Tag Pipeline: Archive Artifacts ==="
                script {
                    bat "echo Release ${env.TAG_NAME} - Build ${BUILD_NUMBER} > build.log"
                    bat "echo Build Date: %DATE% %TIME% >> build.log"
                }
                archiveArtifacts artifacts: 'dist/**,build.log,smoke.log', allowEmptyArchive: false
            }
        }
        
        stage('Cleanup') {
            steps {
                script {
                    echo "=== Tag Pipeline: Cleanup ==="
                    def tag = env.TAG_NAME
                    def containerName = "react_release_${tag.replace('.', '_')}"
                    
                    bat "docker stop ${containerName} 2>nul || exit 0"
                    bat "docker rm ${containerName} 2>nul || exit 0"
                    
                    // DO NOT delete release images - they're for production!
                    echo "✓ Tagged image react:${tag} preserved for deployment"
                    echo "ℹ Release images are kept permanently"
                }
            }
        }
    }
    
    post {
        success {
            echo "======================================"
            echo "✓ RELEASE BUILD SUCCESSFUL"
            echo "======================================"
            echo "Version: ${env.TAG_NAME}"
            echo "Image: react:${env.TAG_NAME}"
            echo "Status: Ready for production deployment"
            echo "======================================"
        }
        failure {
            echo "======================================"
            echo "✗ RELEASE BUILD FAILED"
            echo "======================================"
            echo "Version: ${env.TAG_NAME}"
            echo "Action: Fix issues and create new tag"
            echo "======================================"
        }
    }
}