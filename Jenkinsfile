pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'simple-web-app'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
        DOCKERHUB_USERNAME = 'your-dockerhub-username' // Change this
        WAR_URL = 'https://github.com/Prani2018/dockerbuilds/raw/main/simple-web-app.war'
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
ADD https://github.com/Prani2018/dockerbuilds/raw/main/simple-web-app.war /usr/local/tomcat/webapps/ROOT.war

# Expose Tomcat port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
'''
                }
            }
        }
        
        stage('Download WAR File') {
            steps {
                script {
                    sh """
                        echo 'Downloading WAR file...'
                        curl -L -o simple-web-app.war ${WAR_URL}
                        ls -lh simple-web-app.war
                    """
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    docker.build("${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:${DOCKER_TAG}")
                    docker.build("${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:latest")
                }
            }
        }
        
        stage('Test Docker Image') {
            steps {
                script {
                    echo "Testing Docker image..."
                    sh """
                        # Run container in background
                        docker run -d --name test-container -p 8081:8080 ${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:${DOCKER_TAG}
                        
                        # Wait for Tomcat to start
                        echo 'Waiting for Tomcat to start...'
                        sleep 30
                        
                        # Check if container is running
                        docker ps | grep test-container
                        
                        # Check Tomcat logs
                        docker logs test-container
                        
                        # Test HTTP endpoint
                        curl -f http://localhost:8081 || echo 'Application not ready yet'
                        
                        # Stop and remove test container
                        docker stop test-container
                        docker rm test-container
                    """
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "Pushing to Docker Hub..."
                    docker.withRegistry("https://${DOCKER_REGISTRY}", "${DOCKER_CREDENTIALS_ID}") {
                        docker.image("${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:${DOCKER_TAG}").push()
                        docker.image("${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:latest").push()
                    }
                }
            }
        }
        
        stage('Cleanup Local Images') {
            steps {
                script {
                    sh """
                        docker rmi ${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:${DOCKER_TAG} || true
                        docker rmi ${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:latest || true
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo "✅ SUCCESS: Docker image built and pushed successfully!"
            echo "Image: ${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:${DOCKER_TAG}"
            echo "To run: docker run -p 8080:8080 ${DOCKERHUB_USERNAME}/${DOCKER_IMAGE}:latest"
        }
        failure {
            echo "❌ FAILURE: Pipeline failed. Check logs for details."
        }
        always {
            // Clean up any remaining test containers
            sh '''
                docker stop test-container 2>/dev/null || true
                docker rm test-container 2>/dev/null || true
            '''
            cleanWs()
        }
    }
}
