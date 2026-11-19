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

        stage('3. SonarQube SAST Scan') {
            steps {
                withSonarQubeEnv('SonarQube-Server') {
                    sh 'mvn org.sonarsource.scanner.maven:sonar-maven-plugin:sonar'
                }
            }
        }

        stage('4. Quality Gate Check') {
            steps {
                timeout(time: 3, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('5. Parallel Artifact Publishing') {
            failFast true
            parallel {
                stage('5A. Nexus WAR Upload') {
                    steps {
                        nexusArtifactUploader(
                            nexusVersion: 'nexus3',
                            protocol: 'http',
                            nexusUrl: '54.80.157.53:8081',
                            groupId: 'org.scopeindia',
                            version: '1.0-SNAPSHOT',
                            repository: 'eks-maven-snapshots',
                            credentialsId: 'nexus-creds',
                            artifacts: [[
                                artifactId: 'maven-web-app',
                                classifier: '',
                                file: 'target/maven-web-app.war',
                                type: 'war'
                            ]]
                        )
                    }
                }

                stage('5B. Docker Build & Push') {
                    steps {
                        sh "docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} -t ${DOCKER_IMAGE}:latest ."
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
            }
        }

        stage('6. Deploy & AutoScale on EKS') {
            steps {
                sh '''
                    sed "s|IMAGE_TAG|${IMAGE_TAG}|g" k8s/deployment.yaml | kubectl apply -f -
                    kubectl rollout status deployment/maven-web-app --timeout=180s
                    kubectl get pods,svc,hpa -o wide
                '''
            }
        }
    }

    post {
        success {
            echo "Parallel DevSecOps Pipeline Succeeded! App live on AWS EKS with HPA Auto Scaling."
        }
        always {
            sh 'docker image prune -f || true'
        }
    }
}
