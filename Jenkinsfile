pipeline {
    agent any

    environment {
        APP_NAME        = "docker-app"
        IMAGE_NAME      = "docker-app"
        IMAGE_TAG       = "${BUILD_NUMBER}"
        DOCKER_REGISTRY = "huzefa2612"
        EC2_USER        = "ec2-user"
        EC2_HOST        = "13.203.154.116"
        CONTAINER_PORT  = "8080"    // Tomcat internal port
        HOST_PORT       = "8081"    // External port on EC2
    }

    tools {
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
                echo "Packaging WAR..."
                sh 'mvn -B package -DskipTests'
                archiveArtifacts artifacts: 'target/*.war', fingerprint: true
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image..."
                sh """
                    docker build -t ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} .
                    docker tag ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest
                """
            }
        }

        stage('Push Image to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push $DOCKER_REGISTRY/$IMAGE_NAME:$IMAGE_TAG
                        docker push $DOCKER_REGISTRY/$IMAGE_NAME:latest
                        docker logout
                    '''
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                echo "Deploying to EC2 (${EC2_HOST})..."
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sshagent(['ec2-ssh-creds']) {
                        sh '''
                            ssh -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST "
                                echo '$DOCKER_PASS' | docker login -u '$DOCKER_USER' --password-stdin
                                docker pull $DOCKER_REGISTRY/$IMAGE_NAME:$IMAGE_TAG
                                docker stop $APP_NAME || true
                                docker rm $APP_NAME || true
                                docker run -d \
                                    --name $APP_NAME \
                                    --restart unless-stopped \
                                    -p $HOST_PORT:$CONTAINER_PORT \
                                    $DOCKER_REGISTRY/$IMAGE_NAME:$IMAGE_TAG
                                docker logout
                                docker image prune -f
                            "
                        '''
                    }
                }
            }
        }

    }

    post {
        success { echo "✅ Deployment successful! Build #${BUILD_NUMBER}" }
        failure { echo "❌ Pipeline failed. Check logs." }
    }
}
