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
                sh 'docker build . -t counter:1.0'
            }
        }

        stage('Stop and Remove Existing Container') {
            steps {
                sh '''
                docker ps -q -f name=counter_app | xargs -r docker stop
                docker ps -a -q -f name=counter_app | xargs -r docker rm
                '''
            }
        }

        stage('Run Docker Container') {
            steps {
                sh "docker run -d --name counter_app -p ${DEPLOY_PORT}:8080 counter:1.0"
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

        stage('Deploy Docker Container on EC2') {
            steps {
                script {
                    def keyFile = "${env.WORKSPACE}/aws-ec2-key.pem"
                    withCredentials([string(credentialsId: env.PEM_KEY_CREDENTIALS_ID, variable: 'PEM_KEY')]) {
                        sh """
                        # Write the PEM key to a file, removing any carriage returns
                        echo "\$PEM_KEY" | tr -d '\\r' > ${keyFile}
                        chmod 400 ${keyFile}

                        # Debug: Check the beginning of the key file
                        echo "First 3 lines of key file:"
                        head -n 3 ${keyFile}

                        # Debug: Check key with ssh-keygen
                        ssh-keygen -l -f ${keyFile} || echo "Failed to read key file"

                        # Deploy the Docker container on EC2
                        ssh -v -o StrictHostKeyChecking=no -i ${keyFile} ec2-user@35.153.78.170 << EOF
                        docker pull ${env.ECR_REPO_URI}:latest
                        docker stop counter_app || true
                        docker rm counter_app || true
                        docker run -d --name counter_app -p ${DEPLOY_PORT}:8080 ${env.ECR_REPO_URI}:latest
                        EOF

                        # Remove the key file
                        rm ${keyFile}
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
