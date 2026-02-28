pipeline {
    agent any

    environment {
        // Tomcat server info (IP only, no http:// or port here)
        TOMCAT_SERVER = "43.205.241.205"  
        TOMCAT_USER = "ubuntu"

        // Nexus repo info
        NEXUS_URL = "http://13.126.79.23:8081"
        NEXUS_REPOSITORY = "maven-releases"
        NEXUS_CREDENTIAL_ID = "nexus_creds"

        // SonarQube
        SONAR_HOST_URL = "http://13.232.215.56:9000"
        SONAR_CREDENTIAL_ID = "sonar_creds"
    }

    tools {
        maven "maven"  // predefined Maven tool in Jenkins
    }

    options {
        // Global timeout for entire pipeline (optional)
        timeout(time: 30, unit: 'MINUTES')
    }

    stages {

        stage('Checkout SCM') {
            steps {
                git branch: 'main', 
                    url: 'git@github.com:Bharath-3168/war-web-project.git', 
                    credentialsId: 'github_ssh_key'
            }
        }

        stage('Build WAR') {
            options { timeout(time: 15, unit: 'MINUTES') }
            steps {
                sh 'mvn clean package -DskipTests'
                archiveArtifacts artifacts: 'target/*.war'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube Server') {
                    withCredentials([string(credentialsId: 'sonar_token', variable: 'SONAR_TOKEN')]) {
                        sh """
                        mvn sonar:sonar \
                          -Dsonar.projectKey=wwp \
                          -Dsonar.projectName=wwp \
                          -Dsonar.host.url=$SONAR_HOST_URL \
                          -Dsonar.login=$SONAR_TOKEN
                        """
                    }
                }
            }
        }

        stage('Extract Version') {
            steps {
                script {
                    env.ART_VERSION = sh(script: "mvn help:evaluate -Dexpression=project.version -q -DforceStdout", returnStdout: true).trim()
                    echo "WAR Version: ${env.ART_VERSION}"
                }
            }
        }

        stage('Publish to Nexus') {
            steps {
                script {
                    def warFile = sh(script: 'find target -name "*.war" -print -quit', returnStdout: true).trim()
                    echo "Uploading WAR: ${warFile}"

                    nexusArtifactUploader(
                        nexusVersion: 'nexus3',
                        protocol: 'http',
                        nexusUrl: "${NEXUS_URL}",
                        groupId: 'koddas.web.war',
                        version: "${ART_VERSION}",
                        repository: "${NEXUS_REPOSITORY}",
                        credentialsId: "${NEXUS_CREDENTIAL_ID}",
                        artifacts: [[
                            artifactId: 'wwp',
                            classifier: '',
                            file: warFile,
                            type: 'war'
                        ]]
                    )
                }
            }
        }

        stage('Deploy to Tomcat') {
            options { timeout(time: 10, unit: 'MINUTES') }
            steps {
                script {
                    sh """
                    scp -o StrictHostKeyChecking=no target/*.war ${TOMCAT_USER}@${TOMCAT_SERVER}:/tmp/
                    ssh -o StrictHostKeyChecking=no ${TOMCAT_USER}@${TOMCAT_SERVER} '
                      sudo mv /tmp/*.war /opt/tomcat/webapps/wwp.war
                      sudo systemctl restart tomcat
                    '
                    """
                }
            }
        }

        stage('Display URLs') {
            steps {
                script {
                    def appUrl = "http://${TOMCAT_SERVER}:8080/wwp-${ART_VERSION}"
                    def nexusUrl = "http://${NEXUS_URL}/repository/${NEXUS_REPOSITORY}/koddas/web/war/wwp/${ART_VERSION}/wwp-${ART_VERSION}.war"
                    
                    echo "🌐 Application URL: ${appUrl}"
                    echo "📦 Nexus Artifact URL: ${nexusUrl}"
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed. Check logs for errors.'
        }
    }
}
