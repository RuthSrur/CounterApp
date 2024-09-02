pipeline {
    agent any
    environment {
        AWS_REGION = 'us-east-1'
        AWS_CREDENTIALS_ID = 'aws-credentials-id'
        ECR_REPO_URI_CREDENTIALS_ID = 'ecr-repo-uri-id'
        PEM_KEY_CREDENTIALS_ID = 'aws-ec2-key'
        DEPLOY_PORT = '8081'
        EC2_IP = '18.212.102.249'
        DOCKER_NETWORK = 'monitoring_network'
    }
    stages {
        stage('Build') {
                steps {
                    sh '''
                    # Debug: Print current directory contents
                    ls -la
                    
                    # Debug: Print Docker version
                    docker --version
                    
                    # Stop and remove existing container
                    docker ps -q -f name=counter_app | xargs -r docker stop
                    sleep 5
                    docker ps -a -q -f name=counter_app | xargs -r docker rm

                    # Build Docker Image with verbose output
                    docker build --no-cache -t counter:1.0 . 2>&1 | tee docker_build.log
                    
                    # Debug: Print Docker build log
                    cat docker_build.log

                    # Create Docker network if it doesn't exist
                    docker network create ${DOCKER_NETWORK} || true

                    # Run Docker Container
                    docker run -d --name counter_app --network ${DOCKER_NETWORK} -p ${DEPLOY_PORT}:8081 counter:1.0
                    sleep 10
                    
                    # Debug: Check if container is running
                    docker ps
                    '''
                }
            }
        }
        stage('Unit Tests') {
            steps {
                sh '''
                # Run Unit Tests
                docker exec counter_app python3 -m unittest test_main

                # Cleanup after tests
                docker stop counter_app || true
                docker rm counter_app || true
                '''
            }
        }
        stage('Deploy') {
            when {
                not {
                    branch 'develop'
                }
            }
            steps {
                script {
                    withCredentials([
                        usernamePassword(credentialsId: env.AWS_CREDENTIALS_ID, usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY'),
                        string(credentialsId: env.ECR_REPO_URI_CREDENTIALS_ID, variable: 'ECR_REPO_URI'),
                        file(credentialsId: env.PEM_KEY_CREDENTIALS_ID, variable: 'PEM_KEY_FILE')
                    ]) {
                        // Login to ECR
                        sh '''
                        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID  
                        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                        aws configure set region $AWS_REGION
                        aws ecr-public get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URI
                        '''
                        env.ECR_REPO_URI = ECR_REPO_URI

                        // Tag and Push Docker Image
                        sh """
                        docker tag counter:1.0 ${env.ECR_REPO_URI}:latest
                        docker push ${env.ECR_REPO_URI}:latest
                        """

                        // Deploy to EC2
                        sh """
                        # Create Docker network if it doesn't exist
                        ssh -o StrictHostKeyChecking=no -i ${PEM_KEY_FILE} ec2-user@${EC2_IP} \\
                        'docker network create ${DOCKER_NETWORK} || true'

                        # Stop and remove any existing container with the name 'flask_api_app'
                        ssh -o StrictHostKeyChecking=no -i ${PEM_KEY_FILE} ec2-user@${EC2_IP} \\
                        'docker ps -q --filter "name=flask_api_app" | xargs -r docker stop && \\
                        docker ps -a -q --filter "name=flask_api_app" | xargs -r docker rm'

                        # Pull the latest image from ECR
                        ssh -o StrictHostKeyChecking=no -i ${PEM_KEY_FILE} ec2-user@${EC2_IP} \\
                        'docker pull ${env.ECR_REPO_URI}:latest'

                        # Run a new container with the Flask API on port 8081 (host) mapping to 8081 (container)
                        ssh -o StrictHostKeyChecking=no -i ${PEM_KEY_FILE} ec2-user@${EC2_IP} \\
                        'docker run -d --name flask_api_app --network ${DOCKER_NETWORK} -p 8081:8081 ${env.ECR_REPO_URI}:latest'
                        """
                    }
                }
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}