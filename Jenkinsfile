node {
    // ------------------------
    // Environment Variables
    // ------------------------
    def GIT_REPO = 'https://github.com/madhus-git/sfdcDemoReposistory.git'
    def HUB_ORG_ALIAS = 'devhub'
    def DEV_ORG_ALIAS = 'projectdemosfdc'
    def SFDC_HOST = 'https://login.salesforce.com'

    // Credentials from Jenkins
    def CONNECTED_APP_CONSUMER_KEY = '3MVG9rZjd7MXFdLge17kssqOEkJzHaiSGuSKHEPBMrZc4A67NXuRkwZiSMyK5Bbz4xh9K9hDHKKH5Ug3epFjh'
    def JWT_KEY_FILE = 'a0d4f454-6a6d-42dd-973f-ce6b35acdaf4'
    def SFDC_USERNAME = 'kmadhu.vij380@agentforce.com'

    try {
        stage('Checkout Source') {
            //git branch: 'main', url: "${GIT_REPO}"
            checkout scm
        }

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

        stage('Authenticate Org') {
            //steps {
                //script {
                    if (isUnix()) {
                        sh '''
                          echo "Authenticating to Salesforce Org (Linux)..."
                          sf org login jwt \
                            --client-id $CONNECTED_APP_CONSUMER_KEY \
                            --jwt-key-file $JWT_KEY_FILE \
                            --username $SFDC_USERNAME \
                            --alias $DEV_ORG_ALIAS \
                            --instance-url $SFDC_HOST
                        '''
                    } else {
                        bat '''
                          echo Authenticating to Salesforce Org (Windows)...
                          sf org login jwt ^
                            --client-id %CONNECTED_APP_CONSUMER_KEY% ^
                            --jwt-key-file %JWT_KEY_FILE% ^
                            --username %SFDC_USERNAME% ^
                            --alias %DEV_ORG_ALIAS% ^
                            --instance-url %SFDC_HOST%
                        '''
                    }
                //}
            //}

        }

        stage('Deploy to Dev Org') {
            if (isUnix()) {
                sh "~/sf/bin/sf project deploy start --target-org $DEV_ORG_ALIAS --ignore-conflicts --wait 10"
            } else {
                bat "sf project deploy start --target-org %DEV_ORG_ALIAS% --ignore-conflicts --wait 10"
            }
        }

        echo "✅ Salesforce CI/CD pipeline completed successfully!"

    } catch (err) {
        echo "❌ Pipeline failed: ${err}"
        currentBuild.result = 'FAILURE'
        throw err
    }
}
