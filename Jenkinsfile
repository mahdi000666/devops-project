// Unified Jenkinsfile - detects branch and runs appropriate pipeline

def isPR = env.CHANGE_ID != null
def isDev = env.BRANCH_NAME == 'dev'
def isTag = env.TAG_NAME != null

pipeline {
    agent any
    
    options {
        buildDiscarder(logRotator(numToKeepStr: isPR ? '10' : (isTag ? '20' : '10')))
        disableConcurrentBuilds()
    }
    
    stages {
        stage('Determine Pipeline Type') {
            steps {
                script {
                    if (isTag) {
                        echo "=== RUNNING TAG PIPELINE (${env.TAG_NAME}) ==="
                    } else if (isPR) {
                        echo "=== RUNNING PR PIPELINE (PR-${env.CHANGE_ID}) ==="
                    } else if (isDev) {
                        echo "=== RUNNING DEV PIPELINE ==="
                    } else {
                        echo "=== RUNNING FEATURE PIPELINE ==="
                    }
                }
            }
        }
        
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Setup') {
            steps {
                bat 'npm ci --prefer-offline'
            }
        }
        
        stage('Build') {
            steps {
                script {
                    if (isDev) {
                        // Parallel build for dev
                        parallel(
                            'Node 18': {
                                def commit = env.GIT_COMMIT.take(7)
                                def imageName = "react-dev-node18:${commit}"
                                bat "docker rmi ${imageName} 2>nul || exit 0"
                                bat "docker build --build-arg NODE_VERSION=18 -t ${imageName} ."
                                echo "✓ Node 18 build complete"
                            },
                            'Node 20': {
                                def commit = env.GIT_COMMIT.take(7)
                                def imageName = "react-dev-node20:${commit}"
                                bat "docker rmi ${imageName} 2>nul || exit 0"
                                bat "docker build --build-arg NODE_VERSION=20 -t ${imageName} ."
                                echo "✓ Node 20 build complete"
                            }
                        )
                    } else {
                        // Standard build
                        bat 'npm run build'
                    }
                }
            }
        }
        
        stage('Run Docker') {
            steps {
                script {
                    def imageName
                    def containerName
                    
                    if (isTag) {
                        def tag = env.TAG_NAME
                        imageName = "react:${tag}"
                        containerName = "react_release_${tag.replace('.', '_')}"
                    } else if (isPR) {
                        def prNumber = env.CHANGE_ID
                        def commit = env.GIT_COMMIT.take(7)
                        imageName = "react-pr:${prNumber}-${commit}"
                        containerName = "react_pr_${prNumber}_${BUILD_NUMBER}"
                    } else if (isDev) {
                        def commit = env.GIT_COMMIT.take(7)
                        imageName = "react-dev-node20:${commit}"
                        containerName = "react_dev_${BUILD_NUMBER}"
                    } else {
                        // Feature branch - skip Docker run
                        echo "Feature branch - skipping Docker run"
                        return
                    }
                    
                    // Cleanup port
                    bat """
                        @echo off
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
                    
                    // Build image if not already built (for tag/PR)
                    if (isTag || isPR) {
                        bat "docker rmi ${imageName} 2>nul || exit 0"
                        bat "docker build ${isTag ? '--no-cache' : ''} -t ${imageName} ."
                    }
                    
                    // Run container
                    bat "docker run -d -p 8080:80 --name ${containerName} ${imageName}"
                    bat 'ping 127.0.0.1 -n 6 > nul'
                    echo "✓ Container running at http://localhost:8080"
                }
            }
        }
        
        stage('Smoke Test') {
            when {
                expression { !env.BRANCH_NAME?.startsWith('feature/') }
            }
            steps {
                bat 'call smoke-test.bat http://localhost:8080'
                archiveArtifacts artifacts: 'smoke.log', allowEmptyArchive: true
            }
        }
        
        stage('Archive Artifacts') {
            steps {
                script {
                    if (isTag) {
                        bat "echo Release ${env.TAG_NAME} > build.log"
                        archiveArtifacts artifacts: 'dist/**,build.log,smoke.log', allowEmptyArchive: false
                    } else {
                        bat "echo Build ${BUILD_NUMBER} > build.log"
                        archiveArtifacts artifacts: 'dist/**,build.log', allowEmptyArchive: true
                    }
                }
            }
        }
        
        stage('Cleanup') {
            steps {
                script {
                    if (env.BRANCH_NAME?.startsWith('feature/')) {
                        echo "Feature branch - no cleanup needed"
                        return
                    }
                    
                    def containerName
                    if (isTag) {
                        def tag = env.TAG_NAME
                        containerName = "react_release_${tag.replace('.', '_')}"
                        bat "docker stop ${containerName} 2>nul || exit 0"
                        bat "docker rm ${containerName} 2>nul || exit 0"
                        echo "✓ Release image react:${tag} preserved"
                    } else if (isPR) {
                        def prNumber = env.CHANGE_ID
                        containerName = "react_pr_${prNumber}_${BUILD_NUMBER}"
                        bat "docker stop ${containerName} 2>nul || exit 0"
                        bat "docker rm ${containerName} 2>nul || exit 0"
                        // Clean old PR images
                        bat """
                            @echo off
                            for /f "skip=2 delims=" %%a in ('docker images react-pr --format "{{.Repository}}:{{.Tag}}" 2^>nul') do (
                                docker rmi %%a 2>nul
                            )
                            exit 0
                        """
                    } else if (isDev) {
                        containerName = "react_dev_${BUILD_NUMBER}"
                        bat "docker stop ${containerName} 2>nul || exit 0"
                        bat "docker rm ${containerName} 2>nul || exit 0"
                        // Clean old dev images
                        bat """
                            @echo off
                            for /f "skip=3 delims=" %%a in ('docker images react-dev-node18 --format "{{.Repository}}:{{.Tag}}" 2^>nul') do (
                                docker rmi %%a 2>nul
                            )
                            for /f "skip=3 delims=" %%a in ('docker images react-dev-node20 --format "{{.Repository}}:{{.Tag}}" 2^>nul') do (
                                docker rmi %%a 2>nul
                            )
                            exit 0
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            script {
                if (isTag) {
                    echo "✓ RELEASE ${env.TAG_NAME} - BUILD SUCCESSFUL"
                } else if (isPR) {
                    echo "✓ PR-${env.CHANGE_ID} - VALIDATION PASSED"
                } else if (isDev) {
                    echo "✓ DEV PIPELINE - BUILD SUCCESSFUL"
                } else {
                    echo "✓ FEATURE PIPELINE - BUILD SUCCESSFUL"
                }
            }
        }
        failure {
            script {
                if (isTag) {
                    echo "✗ RELEASE ${env.TAG_NAME} - BUILD FAILED"
                } else if (isPR) {
                    echo "✗ PR-${env.CHANGE_ID} - VALIDATION FAILED"
                } else if (isDev) {
                    echo "✗ DEV PIPELINE - BUILD FAILED"
                } else {
                    echo "✗ FEATURE PIPELINE - BUILD FAILED"
                }
            }
        }
    }
}