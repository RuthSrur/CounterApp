pipeline {
    agent any
    environment {
        AWS_REGION = 'us-east-1'
        AWS_CREDENTIALS_ID = 'aws-credentials-id'
        ECR_REPO_URI_CREDENTIALS_ID = 'ecr-repo-uri-id'
        PEM_KEY_CREDENTIALS_ID = 'aws-ec2-key'
        AWS_CLI_DIR = "${env.JENKINS_HOME}/aws-cli"
        PATH = "${env.PATH}:${AWS_CLI_DIR}/bin"
        DEPLOY_PORT = '8081'
        EC2_IP = '3.93.3.192'
    }
    stages {
        stage('Check and Install AWS CLI') {
            steps {
                script {
                    def awsCliInstalled = sh(script: "if [ -x ${AWS_CLI_DIR}/bin/aws ]; then ${AWS_CLI_DIR}/bin/aws --version; else echo 'not installed'; fi", returnStdout: true).trim()
                    if (awsCliInstalled.contains('aws-cli')) {
                        echo "AWS CLI already installed: ${awsCliInstalled}"
                    } else {
                        sh '''
                        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                        unzip awscliv2.zip
                        ./aws/install -i ${AWS_CLI_DIR} -b ${AWS_CLI_DIR}/bin
                        aws --version
                        '''
                    }
                }
            }
        }

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

        stage('Deploy') {
            when {
                not {
                    branch 'develop'
                }
            }
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: env.AWS_CREDENTIALS_ID, usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY'),
                                     string(credentialsId: env.ECR_REPO_URI_CREDENTIALS_ID, variable: 'ECR_REPO_URI'),
                                     file(credentialsId: env.PEM_KEY_CREDENTIALS_ID, variable: 'PEM_KEY_FILE')]) {
                        sh """
                        # Configure AWS CLI
                        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID  
                        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                        aws configure set region $AWS_REGION

                        # Login to ECR
                        aws ecr-public get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URI

                        # Tag Docker Image
                        docker tag counter:1.0 ${ECR_REPO_URI}:latest

                        # Push Docker Image to ECR
                        docker push ${ECR_REPO_URI}:latest

                        # Deploy to EC2
                        ssh -o StrictHostKeyChecking=no -i ${PEM_KEY_FILE} ec2-user@${EC2_IP} \\
                        'docker ps -q --filter "name=flask_api_app" | xargs -r docker stop && \\
                        docker ps -a -q --filter "name=flask_api_app" | xargs -r docker rm && \\
                        docker pull ${ECR_REPO_URI}:latest && \\
                        docker run -d --name flask_api_app -p 8081:8081 ${ECR_REPO_URI}:latest'
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
