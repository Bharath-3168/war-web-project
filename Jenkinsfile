pipeline {
    agent any

    tools {
        jdk 'JDK 17'
        maven 'Maven 3.9.0'
    }

    environment {
        GIT_CREDENTIALS = '03d5190e-07d0-4f41-9ed2-6315b9b35004'
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

        stage('Publish to Nexus') {
            steps {
                nexusArtifactUploader(
                    nexusVersion: 'nexus3',
                    protocol: 'http',
                    nexusUrl: 'your-nexus-server',
                    repository: "${NEXUS_REPO_ID}",
                    credentialsId: "${NEXUS_CREDENTIALS}",
                    groupId: 'com.example',
                    version: "${env.PROJECT_VERSION}",
                    artifactId: 'war-web-project',
                    packaging: 'war',
                    file: 'target/war-web-project.war'
                )
            }
        }

        stage('Deploy to Tomcat with Rollback') {
            steps {
                script {
                    echo "Backing up current WAR (if exists)..."
                    sh """
                    curl -u \${TOMCAT_CREDENTIALS_USR}:\${TOMCAT_CREDENTIALS_PSW} -O ${TOMCAT_URL}${APP_PATH}.war || true
                    mv ${APP_PATH}.war ${APP_PATH}_backup.war || true
                    """

                    try {
                        echo "Deploying new WAR..."
                        deploy adapters: [tomcat9(credentialsId: "${TOMCAT_CREDENTIALS}", path: "${APP_PATH}", url: "${TOMCAT_URL}")],
                               contextPath: "${APP_PATH}",
                               war: 'target/war-web-project.war'
                    } catch (err) {
                        echo "Deployment failed! Rolling back..."
                        sh """
                        if [ -f ${APP_PATH}_backup.war ]; then
                            deploy adapters: [tomcat9(credentialsId: "${TOMCAT_CREDENTIALS}", path: "${APP_PATH}", url: "${TOMCAT_URL}")],
                                   contextPath: "${APP_PATH}",
                                   war: "${APP_PATH}_backup.war"
                        fi
                        """
                        error "Deployment failed and rollback executed."
                    }
                }
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
