pipeline {
    agent any

    stages {
        stage('Build Docker image') {
            steps {
                sh 'docker build . -t weather_app:v1.2'
            }
        }

        stage('Run Docker container') {
            steps {
                script {
                    echo "Starting Docker container"
                    sh 'docker run -d --name weather_app_container -p 5000:5000 weather_app:v1.2'
                }
            }
        }

        stage('Run Tests') {
            steps {
                script {
                    echo "Running tests in Docker container"
                    sh 'docker exec weather_app_container python3 -m unittest test_main.py'
                }
            }
        }

        stage('Cleanup') {
            steps {
                script {
                    echo "Cleaning up Docker container"
                    sh 'docker stop weather_app_container'
                    sh 'docker rm weather_app_container'
                }
            }
        }
    }
}
