pipeline {
    agent slave1

    tools {
        maven 'maven3'
    }

    stages {

        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Deploy to Dev Tomcat') {
            when {
                branch 'dev'
            }
            steps {
                deploy adapters: [
                    tomcat9(
                        url: 'http://13.201.85.213:8080/',
                        credentialsId: 'tomcat-cred',
                        path: '/manager/text'
                    )
                ], contextPath: 'myapp-dev', war: 'target/*.war'
            }
        }

        stage('Deploy to Prod Tomcat') {
            when {
                branch 'master'
            }
            steps {
                deploy adapters: [
                    tomcat9(
                        url: 'http://13.201.85.213:8080/',
                        credentialsId: 'tomcat-cred',
                        path: '/manager/text'
                    )
                ], contextPath: 'myapp-prod', war: 'target/*.war'
            }
        }
    }

    post {
        success {
            echo "Deployment successful on branch ${env.BRANCH_NAME}"
        }
        failure {
            echo "Pipeline failed. Check the logs above."
        }
    }
}
