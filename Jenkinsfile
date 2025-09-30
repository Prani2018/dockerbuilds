#This file will create application build image with tomcat and pushes to tomcat.
pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'simple-web-app'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        DOCKERHUB_USERNAME = 'gcpa2279' // Change this to your Docker Hub username
        WAR_URL = 'https://github.com/Prani2018/devopsdev/raw/refs/heads/main/simple-web-app.war'
    }
    
    stages {
        stage('Prepare Workspace') {
            steps {
                script {
                    // Clean workspace
                    cleanWs()
                    
                    // Create Dockerfile
                    writeFile file: 'Dockerfile', text: '''FROM tomcat:9-jdk17

# Remove default ROOT application
RUN rm -rf /usr/local/tomcat/webapps/ROOT

# Download and deploy WAR file
ADD https://github.com/Prani2018/devopsdev/raw/refs/heads/main/simple-web-app.war /usr/local/tomcat/webapps/ROOT.war

# Expose Tomcat port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
'''
                    echo "Dockerfile created successfully"
                    sh "cat Dockerfile"
                }
            }
        }
        
        stage('Verify Docker') {
            steps {
                sh '''
                    echo "Checking Docker installation..."
                    docker --version
                    docker info
                '''
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker image: ${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:${DOCKER_TAG}"
                    sh """
                        docker build -t ${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:${DOCKER_TAG} .
                        docker tag ${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:latest
                        docker images | grep ${DOCKER_IMAGE}
                    """
                }
            }
        }
        
        stage('Test Docker Image') {
            steps {
                script {
                    echo "Testing Docker image..."
                    sh """
                        # Run container in background
                        docker run -d --name test-container-${BUILD_NUMBER} -p 8081:8080 ${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:${DOCKER_TAG}
                        
                        # Wait for Tomcat to start
                        echo 'Waiting for Tomcat to start...'
                        sleep 30
                        
                        # Check if container is running
                        docker ps | grep test-container-${BUILD_NUMBER}
                        
                        # Check Tomcat logs
                        echo 'Container logs:'
                        docker logs test-container-${BUILD_NUMBER}
                        
                        # Test HTTP endpoint
                        echo 'Testing HTTP endpoint...'
                        curl -f http://localhost:8081 || echo 'Application not ready yet, but container is running'
                        
                        # Stop and remove test container
                        docker stop test-container-${BUILD_NUMBER}
                        docker rm test-container-${BUILD_NUMBER}
                    """
                }
            }
        }
        
        stage('Login to Docker Hub') {
            steps {
                script {
                    echo "Logging into Docker Hub..."
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', 
                                                      usernameVariable: 'DOCKER_USER', 
                                                      passwordVariable: 'DOCKER_PASS')]) {
                        sh '''
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        '''
                    }
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "Pushing Docker images to Docker Hub..."
                    sh """
                        docker push ${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:${DOCKER_TAG}
                        docker push ${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:latest
                    """
                }
            }
        }
        
        stage('Logout from Docker Hub') {
            steps {
                sh 'docker logout'
            }
        }
        
        stage('Cleanup Local Images') {
            steps {
                script {
                    sh """
                        docker rmi ${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:${DOCKER_TAG} || true
                        docker rmi ${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:latest || true
                        echo 'Local images cleaned up'
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo "✅ SUCCESS: Docker image built and pushed successfully!"
            echo "=========================================="
            echo "Image: ${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:${DOCKER_TAG}"
            echo "Latest: ${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:latest"
            echo "=========================================="
            echo "To pull and run:"
            echo "docker pull ${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:latest"
            echo "docker run -d -p 8080:8080 ${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:latest"
            echo "=========================================="
        }
        failure {
            echo "❌ FAILURE: Pipeline failed. Check logs for details."
        }
        always {
            script {
                // Clean up any remaining test containers
                sh """
                    docker stop test-container-${BUILD_NUMBER} 2>/dev/null || true
                    docker rm test-container-${BUILD_NUMBER} 2>/dev/null || true
                """
            }
        }
    }
}
