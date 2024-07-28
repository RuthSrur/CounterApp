pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1' 
        AWS_CREDENTIALS_ID = 'aws-credentials-id' 
        ECR_REPO_URI_CREDENTIALS_ID = 'ECR-URI' 
    }

    stages {
        stage('Install AWS CLI') {
            steps {
                sh '''
                apt-get update
                apt-get install -y curl unzip
                curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                unzip awscliv2.zip
                ./aws/install
                rm -rf awscliv2.zip aws
                '''
            }
        }

        stage('Build Docker image') {
            steps {
                sh 'docker build . -t counter:1.0'
            }
        }

        stage('Stop and Remove Existing Container') {
            steps {
                script {
                    // Stop and remove the container if it exists
                    sh '''
                    docker ps -q -f name=counter_app | xargs -r docker stop
                    docker ps -a -q -f name=counter_app | xargs -r docker rm
                    '''
                }
            }
        }

        stage('Run Docker container') {
            steps {
                script {
                    // Run the Docker container
                    sh 'docker run -d --name counter_app -p 8080:8080 counter:1.0'
                    
                    // Wait for the container to be ready
                    sleep 10
                }
            }
        }

        stage('Run Unit Tests') {
            steps {
                script {
                    // Run unit tests in the Docker container
                    sh '''
                    docker exec counter_app python3 -m unittest test_main
                    '''
                }
            }
        }

        stage('Cleanup') {
            steps {
                script {
                    // Stop and remove the container after tests
                    sh '''
                    docker stop counter_app || true
                    docker rm counter_app || true
                    '''
                }
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([usernamePassword(credentialsId: env.AWS_CREDENTIALS_ID, usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY'),
                                 string(credentialsId: env.ECR_REPO_URI_CREDENTIALS_ID, variable: 'ECR_REPO_URI')]) {
                    script {
                        // Authenticate Docker to the ECR registry
                        sh '''
                        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URI
                        '''
                    }
                }
            }
        }

        stage('Tag Docker Image') {
            steps {
                script {
                    // Tag the Docker image with the ECR repository URI
                    sh 'docker tag counter:1.0 $ECR_REPO_URI:1.0'
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                script {
                    // Push the Docker image to ECR
                    sh 'docker push $ECR_REPO_URI:1.0'
                }
            }
        }
    }
}
