pipeline {
    agent any
    environment {
        AWS_REGION = 'us-east-1'
        AWS_CLI_DIR = "${env.JENKINS_HOME}/aws-cli"
    }
    stages {
        stage('Install AWS CLI') {
            steps {
                sh """
                curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                unzip awscliv2.zip
                ./aws/install -i ${AWS_CLI_DIR} -b ${AWS_CLI_DIR}/bin
                export PATH="\${PATH}:${AWS_CLI_DIR}/bin"
                aws --version
                """
            }
        }
        
        stage('Build Docker Image') {
            steps {
                sh 'docker build . -t counter:1.0'
            }
        }
        
        stage('Stop and Remove Existing Container') {
            steps {
                script {
                    sh '''
                    docker ps -q -f name=counter_app | xargs -r docker stop
                    docker ps -a -q -f name=counter_app | xargs -r docker rm
                    '''
                }
            }
        }
        
        stage('Run Docker Container') {
            steps {
                script {
                    sh 'docker run -d --name counter_app -p 8080:8080 counter:1.0'
                    sleep 10
                }
            }
        }
        
        stage('Run Unit Tests') {
            steps {
                script {
                    sh '''
                    docker exec counter_app python3 -m unittest test_main
                    '''
                }
            }
        }
        
        stage('Cleanup') {
            steps {
                script {
                    sh '''
                    docker stop counter_app || true
                    docker rm counter_app || true
                    '''
                }
            }
        }
        
        stage('Login to ECR') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-credentials-id', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY'),
                                 string(credentialsId: 'ecr-repo-uri-id', variable: 'ECR_REPO_URI')]) {
                    script {
                        sh """
                        export PATH="\${PATH}:${AWS_CLI_DIR}/bin"
                        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                        aws configure set region $AWS_REGION
                        aws ecr-public get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URI
                        """
                    }
                }
            }
        }
        
        stage('Print ECR URI') {
            steps {
                script {
                    echo "ECR_REPO_URI: ${env.ECR_REPO_URI}"
                }
            }
        }
        
        stage('Tag Docker Image') {
            steps {
                script {
                    echo "ECR_REPO_URI before tagging: ${env.ECR_REPO_URI}"
                    sh 'docker tag counter:1.0 ${env.ECR_REPO_URI}:latest'
                }
            }
        }
        
        stage('Push Docker Image to ECR') {
            steps {
                script {
                    sh """
                    export PATH="\${PATH}:${AWS_CLI_DIR}/bin"
                    docker push ${env.ECR_REPO_URI}:latest
                    """
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
