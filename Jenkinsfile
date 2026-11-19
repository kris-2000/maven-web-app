pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "krishnajune2000/maven-web-app"
        IMAGE_TAG    = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('1. Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('2. Maven Build') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('3. Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} -t ${DOCKER_IMAGE}:latest ."
            }
        }

        stage('4. Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${DOCKER_IMAGE}:${IMAGE_TAG}
                        docker push ${DOCKER_IMAGE}:latest
                        docker logout
                    '''
                }
            }
        }

        stage('5. Deploy to AWS EKS') {
            steps {
                sh '''
                    sed "s|IMAGE_TAG|${IMAGE_TAG}|g" k8s/deployment.yaml | kubectl apply -f -
                    kubectl rollout status deployment/maven-web-app --timeout=180s
                    kubectl get pods,svc -o wide
                '''
            }
        }
    }

    post {
        success {
            echo "Rollout Complete! Check EXTERNAL-IP in 'kubectl get svc maven-web-app-svc'."
        }
        always {
            sh 'docker image prune -f || true'
        }
    }
}
