pipeline {
    agent any

    environment {
        APP_NAME        = "docker-app"
        IMAGE_NAME      = "docker-app"
        IMAGE_TAG       = "${BUILD_NUMBER}"
        DOCKER_REGISTRY = "huzefa2612"   // or ECR/private registry
        EC2_HOST        = "ec2-user@13.203.154.116"          // EC2 public IP / DNS
        EC2_USER        = "ec2-user"
        CONTAINER_PORT  = "8081"
        HOST_PORT       = "8081"
    }

    tools {
        // Make sure these are configured in Manage Jenkins -> Global Tool Configuration
        maven 'maven3'
    }

    stages {

        stage('Build') {
            steps {
                echo "Building ${APP_NAME}..."
                sh 'mvn -B clean compile'
            }
        }

        stage('Test') {
            steps {
                echo "Running unit tests..."
                sh 'mvn -B test'
            }
        }

        stage('Package') {
            steps {
                echo "Packaging jar/war..."
                sh 'mvn -B package -DskipTests'
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image..."
                sh """
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
                """
            }
        }

        stage('Push Image to Registry') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                echo "Deploying to EC2 (${EC2_HOST})..."
                sshagent(['ec2-ssh-creds']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${EC2_HOST} '
                            docker login -u ${DOCKER_REGISTRY} || true
                            docker pull ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                            docker stop ${APP_NAME} || true
                            docker rm ${APP_NAME} || true
                            docker run -d \
                                --name ${APP_NAME} \
                                --restart unless-stopped \
                                -p ${HOST_PORT}:${CONTAINER_PORT} \
                                ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                            docker image prune -f
                        '
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful! Build #${BUILD_NUMBER}"
        }
        failure {
            echo "❌ Pipeline failed. Check logs."
        }
        always {
            cleanWs()
        }
    }
}
