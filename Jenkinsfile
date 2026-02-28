pipeline {
    agent any

    tools {
        jdk 'Default'       // match Jenkins configuration
        maven 'Maven 3.8.8' // match Jenkins configuration
    }

    environment {
        GIT_CREDENTIALS = '03d5190e-07d0-4f41-9ed2-6315b35004'
        SONARQUBE_SERVER = 'SonarQube_Server'
        NEXUS_REPO_ID = 'maven-releases'
        NEXUS_CREDENTIALS = 'nexus_credentials_id'
        TOMCAT_CREDENTIALS = 'tomcat_credentials_id'
        TOMCAT_URL = 'http://43.205.241.205:8080'
        APP_PATH = '/war-web-project'
    }

    stages {
        stage('Checkout SCM') {
            steps {
                git(
                    url: 'https://github.com/Bharath-3168/war-web-project.git',
                    branch: 'master',
                    credentialsId: "${GIT_CREDENTIALS}"
                )
            }
        }

        stage('Build WAR') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONARQUBE_SERVER}") {
                    sh 'mvn sonar:sonar'
                }
            }
        }

        stage('Extract Version') {
            steps {
                script {
                    def pom = readMavenPom file: 'pom.xml'
                    env.PROJECT_VERSION = pom.version
                    echo "Project version: ${env.PROJECT_VERSION}"
                }
            }
        }

        stage('Publish WAR to Nexus') {
            steps {
                nexusArtifactUploader(
                    nexusVersion: 'nexus3',
                    protocol: 'http',
                    nexusUrl: 'your-nexus-server',
                    repository: "${NEXUS_REPO_ID}",
                    credentialsId: "${NEXUS_CREDENTIALS}",
                    groupId: 'com.example',
                    version: "${env.PROJECT_VERSION}",
                    artifacts: [
                        [artifactId: 'war-web-project', classifier: '', file: 'target/war-web-project.war', type: 'war']
                    ]
                )
            }
        }

        stage('Deploy to Tomcat') {
            steps {
                deploy adapters: [tomcat9(
                    credentialsId: "${TOMCAT_CREDENTIALS}",
                    path: "${APP_PATH}",
                    url: "${TOMCAT_URL}",
                    rollbackOnFailure: true
                )],
                contextPath: "${APP_PATH}",
                war: 'target/war-web-project.war'
            }
        }

        stage('Display URLs') {
            steps {
                echo "Application deployed at: ${TOMCAT_URL}${APP_PATH}"
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline succeeded!"
        }
        failure {
            echo "❌ Pipeline failed. Check logs for errors."
        }
    }
}
