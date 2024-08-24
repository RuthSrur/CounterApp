pipeline {
    agent any
    environment {
        AWS_REGION = 'us-east-1'
        AWS_CREDENTIALS_ID = 'aws-credentials-id'
        ECR_REPO_URI_CREDENTIALS_ID = 'ecr-repo-uri-id'
        PEM_KEY_CREDENTIALS_ID = 'aws-ec2-key'
        DEPLOY_PORT = '8081'
        EC2_IP = '3.92.68.16'
    }
    stages {
        stage('Build Docker Image') {
            steps {
                sh 'docker build --no-cache -t counter:1.0 .'
            }
        }

        stage('Stop and Remove Existing Container') {
            steps {
                sh '''
                docker ps -q -f name=counter_app | xargs -r docker stop
                sleep 5  # Wait to ensure the port is freed up
                docker ps -a -q -f name=counter_app | xargs -r docker rm
                '''
            }
        }

        stage('Run Docker Container') {
            steps {
                sh "docker run -d --name counter_app -p ${DEPLOY_PORT}:8081 counter:1.0"
                sleep 10
            }
        }

        stage('Run Unit Tests') {
            steps {
                sh 'docker exec counter_app python3 -m unittest test_main'
            }
        }

        stage('Cleanup') {
            steps {
                sh '''
                docker stop counter_app || true
                docker rm counter_app || true
                '''
            }
        }

        stage('Login to ECR') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: env.AWS_CREDENTIALS_ID, usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY'),
                                     string(credentialsId: env.ECR_REPO_URI_CREDENTIALS_ID, variable: 'ECR_REPO_URI')]) {
                        sh '''
                        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID  
                        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                        aws configure set region $AWS_REGION
                        aws ecr-public get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URI
                        '''
                        env.ECR_REPO_URI = ECR_REPO_URI
                    }
                }
            }
        }

        stage('Tag Docker Image') {
            steps {
                sh "docker tag counter:1.0 ${env.ECR_REPO_URI}:latest"
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                sh "docker push ${env.ECR_REPO_URI}:latest"
            }
        }

        stage('Deploy to EC2') {
            when {
                not {
                    branch 'develop'
                }
            }
            steps {
                script {
                    withCredentials([file(credentialsId: env.PEM_KEY_CREDENTIALS_ID, variable: 'PEM_KEY_FILE')]) {
                        sh """
                        # Stop and remove any existing container with the name 'flask_api_app'
                        ssh -o StrictHostKeyChecking=no -i ${PEM_KEY_FILE} ec2-user@${EC2_IP} \\
                        'docker ps -q --filter "name=flask_api_app" | xargs -r docker stop && \\
                        docker ps -a -q --filter "name=flask_api_app" | xargs -r docker rm'

                        # Pull the latest image from ECR
                        ssh -o StrictHostKeyChecking=no -i ${PEM_KEY_FILE} ec2-user@${EC2_IP} \\
                        'docker pull ${env.ECR_REPO_URI}:latest'

                        # Run a new container with the Flask API on port 8081 (host) mapping to 8081 (container)
                        ssh -o StrictHostKeyChecking=no -i ${PEM_KEY_FILE} ec2-user@${EC2_IP} \\
                        'docker run -d --name flask_api_app -p 8081:8081 ${env.ECR_REPO_URI}:latest'
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
