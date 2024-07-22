pipeline {
    agent any

    stages {
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
                    docker exec counter_app python3 -m unittest test_app
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
    }
}
