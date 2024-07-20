pipeline {
    agent any

    stages {
        stage('Build Docker image') {
            steps {
                sh 'docker build . -t counter:1.0'
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
                    docker run --rm \
                      --name test_runner \
                      --network host \
                      -v $(pwd):/usr/src/app \
                      -w /usr/src/app \
                      python:3.9 \
                      bash -c "pip install -r requirements.txt && python -m unittest discover -s . -p 'test_app.py'"
                    '''
                }
            }
        }

        stage('Cleanup') {
            steps {
                script {
                    // Stop and remove the container after tests
                    sh 'docker stop counter_app || true'
                    sh 'docker rm counter_app || true'
                }
            }
        }
    }
}
