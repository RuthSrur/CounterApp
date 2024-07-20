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
                    echo "hello"
                }
            }
        }
    }
}