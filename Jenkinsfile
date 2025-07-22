pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        S3_BUCKET = 'mydemobucket-2810'
        REPO_URL = 'https://github.com/preethichowdaryb/aws-s3-etl-demo.git'
    }

    triggers {
        githubPush()  // Auto-trigger on GitHub push events
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo "Cloning repository from ${REPO_URL}..."
                git branch: 'main', url: "${REPO_URL}"
            }
        }

        stage('Verify CSV Files') {
            steps {
                echo "Listing CSV files in data folder..."
                sh 'ls -lh data/*.csv || echo "No CSV files found!"'
            }
        }

        stage('Upload to S3') {
            steps {
                withAWS(region: 'us-east-1', credentials: 'AWS conf with jenkins') {
                    echo "Syncing CSV files to S3 bucket ${S3_BUCKET}..."
                    sh "aws s3 sync data/ s3://${S3_BUCKET}/data/ --exact-timestamps"
                }
            }
        }
    }

    post {
        success {
            echo " CSV files successfully uploaded to S3 bucket ${S3_BUCKET}"
        }
        failure {
            echo " Pipeline failed! Check logs."
        }
    }
}

