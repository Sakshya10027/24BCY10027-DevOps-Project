pipeline {
    agent any

    environment {
        // Change these to match your setup
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds') // Jenkins credential ID
        DOCKER_IMAGE = "noctro29/abc-technologies-website"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Cloning repository from GitHub...'
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                sh 'docker build -t $DOCKER_IMAGE:$IMAGE_TAG -t $DOCKER_IMAGE:latest .'
            }
        }

        stage('Login to Docker Hub') {
            steps {
                sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
            }
        }

        stage('Push Docker Image') {
            steps {
                echo 'Pushing Docker image to Docker Hub...'
                sh 'docker push $DOCKER_IMAGE:$IMAGE_TAG'
                sh 'docker push $DOCKER_IMAGE:latest'
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo 'Deploying to Kubernetes cluster...'
                sh '''
                    kubectl set image deployment/abc-website-deployment \
                        abc-website=$DOCKER_IMAGE:$IMAGE_TAG --record || \
                    kubectl apply -f k8s/deployment.yaml
                    kubectl apply -f k8s/service.yaml
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh 'kubectl rollout status deployment/abc-website-deployment'
                sh 'kubectl get pods -o wide'
                sh 'kubectl get svc abc-website-service'
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully! Take your Jenkins console screenshot now.'
        }
        failure {
            echo 'Pipeline failed. Check console output for details.'
        }
        always {
            sh 'docker logout'
        }
    }
}
