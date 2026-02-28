pipeline {
    agent any

    environment {
        TOMCAT_SERVER = "http://43.205.241.205:8080/"
        TOMCAT_USER = "ubuntu"
        NEXUS_URL = "13.126.79.23:8081"
        NEXUS_REPOSITORY = "maven-releases"
        NEXUS_CREDENTIAL_ID = "nexus_creds"
        SSH_KEY_PATH = "/var/lib/jenkins/.ssh/jenkins_key"
        SONAR_HOST_URL = "http://13.232.215.56:9000"
        SONAR_CREDENTIAL_ID = "sonar_creds"  // Replace with your SonarQube credential ID
    }

    tools {
        maven 'maven'
    }

    stages {
                stage('Build WAR') {
            steps {
                sh 'mvn clean package -DskipTests'
                archiveArtifacts artifacts: 'target/*.war'
            }
        }
stage('SonarQube Analysis') {
    steps {
        withSonarQubeEnv('SonarQube Server') {
            withCredentials([
                string(credentialsId: 'sonar_token', variable: 'SONAR_TOKEN')
            ]) {
                sh '''
                  mvn sonar:sonar \
                  -Dsonar.projectKey=wwp \
                  -Dsonar.projectName=wwp \
                  -Dsonar.host.url=$SONAR_HOST_URL \
                  -Dsonar.login=$SONAR_TOKEN
                '''
            }
        }
    }
}

       stage('Extract Version') {
            steps {
                script {
                    env.ART_VERSION = sh(script: "mvn help:evaluate -Dexpression=project.version -q -DforceStdout", returnStdout: true).trim()
                }
            }
        }

           stage('Publish to Nexus') {
            steps {
                script {
                    echo "⬆️ Uploading WAR to Nexus repository..."
                    def warFile = sh(script: 'find target -name "*.war" -print -quit', returnStdout: true).trim()
                    echo "Uploading file: ${warFile}"

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
    steps {
        script {
            sh """
            scp -o StrictHostKeyChecking=no target/*.war ubuntu@$TOMCAT_SERVER:/tmp/

            ssh -o StrictHostKeyChecking=no ubuntu@$TOMCAT_SERVER '
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
            echo '❌ Pipeline failed. Check the logs for errors.'
        }
    }
}
