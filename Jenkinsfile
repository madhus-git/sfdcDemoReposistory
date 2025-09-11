// Utility Functions
def authenticateOrg(orgAlias, sfdcHost, consumerKey, jwtKeyFile, username) {
    if (isUnix()) {
        sh """
            echo "Authenticating to Salesforce Org: ${orgAlias}..."
            sf org login jwt --client-id ${consumerKey} \
                             --jwt-key-file ${jwtKeyFile} \
                             --username ${username} \
                             --alias ${orgAlias} \
                             --instance-url ${sfdcHost}
        """
    } else {
        bat """
            echo Authenticating to Salesforce Org: ${orgAlias}...
            sf org login jwt --client-id %CONNECTED_APP_CONSUMER_KEY% \
                             --jwt-key-file %JWT_KEY_FILE% \
                             --username %SFDC_USERNAME% \
                             --alias ${orgAlias} \
                             --instance-url ${sfdcHost}
        """
    }
}

def deployToOrg(orgAlias) {
    if (isUnix()) {
        sh "sf project deploy start --target-org ${orgAlias} --ignore-conflicts --wait 10"
    } else {
        bat "sf project deploy start --target-org ${orgAlias} --ignore-conflicts --wait 10"
    }
}

node {
    try{
        // Global Credentials
        withCredentials([
            string(credentialsId: 'sfdc-consumer-key', variable: 'CONNECTED_APP_CONSUMER_KEY'),
            string(credentialsId: 'sfdc-username', variable: 'SFDC_USERNAME'),
            file(credentialsId: 'sfdc-jwt-key', variable: 'JWT_KEY_FILE')
        ]) {
            // Global Environment Variables
            def SFDC_HOST = 'https://login.salesforce.com'
            def DEV_ORG_ALIAS = 'projectdemosfdc'

            // Slack channel and webhook (replace with your channel)
            /*env.SLACK_CHANNEL = '#devops-alerts'
            env.SLACK_CREDENTIALS_ID = 'slack-webhook-url' 

            // Utility Functions
            def slackNotify(message, color = 'good') {
                slackSend(channel: env.SLACK_CHANNEL, 
                          color: color, 
                          message: message, 
                          webhookUrl: credentials(env.SLACK_CREDENTIALS_ID))
            } */

            // Pipeline Stages

            stage('Pipeline Start') {
                echo "🚀 Salesforce CI/CD pipeline started!"
                //slackNotify("🚀 Salesforce CI/CD pipeline started for project ${env.JOB_NAME} (#${env.BUILD_NUMBER})")
            }

            // Checkout Source
            stage('Checkout Source') {
                checkout scm
            }

            // Install SF CLI
            stage('Install Salesforce CLI') {
                if (isUnix()) {
                    sh '''
                        if ! command -v sf >/dev/null 2>&1; then
                            echo "Salesforce CLI not found, installing..."
                            npm install --global @salesforce/cli
                        else
                            echo "Salesforce CLI is already installed."
                            sf --version
                        fi
                    '''
                } else {
                    bat '''
                        where sf >nul 2>nul
                        if %ERRORLEVEL% neq 0 (
                            echo Salesforce CLI not found, installing...
                            npm install --global @salesforce/cli
                        ) else (
                            echo Salesforce CLI is already installed.
                            sf --version
                        )
                    '''
                }
            }

            // Authenticate to Org
            stage('Authenticate Dev Org') { 
                authenticateOrg(DEV_ORG_ALIAS, SFDC_HOST, CONNECTED_APP_CONSUMER_KEY, JWT_KEY_FILE, SFDC_USERNAME)
                //slackNotify("✅ Authenticated Dev Org: $DEV_ORG_ALIAS")
            }

            // Deploy to Dev Org
            stage('Deploy to Dev Org') { 
                deployToOrg(DEV_ORG_ALIAS)
                //slackNotify("✅ Deployment to Dev Org completed")
            }

            //Pipeline Complete
            stage('Pipeline Complete') {
                echo "🎉 Salesforce CI/CD pipeline completed successfully!"
                //slackNotify("🎉 Salesforce CI/CD pipeline completed successfully for project ${env.JOB_NAME} (#${env.BUILD_NUMBER})")
            }
        } //end of withCredentials
    } catch (err) {
        echo "❌ Pipeline failed: ${err}"
        //slackNotify("❌ Salesforce CI/CD pipeline FAILED for project ${env.JOB_NAME} (#${env.BUILD_NUMBER})", 'danger')
        currentBuild.result = 'FAILURE'
        throw err
    }
}