node {
    // ------------------------
    // Environment Variables
    // ------------------------
    def GIT_REPO = 'https://github.com/your-org/your-salesforce-repo.git'
    def HUB_ORG_ALIAS = 'devhub'
    def DEV_ORG_ALIAS = 'projectdemosfdc'
    def SFDC_HOST = 'https://login.salesforce.com'

    // Credentials from Jenkins
    def CONNECTED_APP_CONSUMER_KEY = '3MVG9rZjd7MXFdLge17kssqOEkJzHaiSGuSKHEPBMrZc4A67NXuRkwZiSMyK5Bbz4xh9K9hDHKKH5Ug3epFjh'
    def JWT_KEY_FILE = 'a0d4f454-6a6d-42dd-973f-ce6b35acdaf4'
    def SFDC_USERNAME = 'kmadhu.vij380@agentforce.com'

    try {
        stage('Checkout Source') {
            git branch: 'main', url: "${GIT_REPO}"
        }

        stage('Install Salesforce CLI') {
            if (isUnix()) {
                sh '''
                    if ! command -v sf &> /dev/null
                    then
                        echo "Installing Salesforce CLI (Linux)..."
                        curl -fsSL https://developer.salesforce.com/media/salesforce-cli/sf/channels/stable/sf-linux-x64.tar.xz -o sf.tar.xz
                        mkdir -p ~/sf
                        tar -xJf sf.tar.xz -C ~/sf --strip-components 1
                        export PATH=$PATH:~/sf/bin
                        echo "Salesforce CLI installed successfully."
                    else
                        echo "Salesforce CLI already installed."
                    fi
                '''
            } else {
                bat '''
                    where sf >nul 2>nul
                    if %errorlevel% neq 0 (
                        echo Installing Salesforce CLI (Windows)...
                        npm install --global @salesforce/cli
                    ) else (
                        echo Salesforce CLI already installed.
                    )
                '''
            }
        }

        stage('Authenticate Org') {
            if (isUnix()) {
                sh """
                    echo 'Authenticating to Salesforce Org...'
                    ~/sf/bin/sf org login jwt \
                        --client-id $CONNECTED_APP_CONSUMER_KEY \
                        --jwt-key-file $JWT_KEY_FILE \
                        --username $SFDC_USERNAME \
                        --alias $DEV_ORG_ALIAS \
                        --instance-url $SFDC_HOST
                """
            } else {
                bat """
                    echo Authenticating to Salesforce Org (Windows)...
                    sf org login jwt ^
                        --client-id %CONNECTED_APP_CONSUMER_KEY% ^
                        --jwt-key-file %JWT_KEY_FILE% ^
                        --username %SFDC_USERNAME% ^
                        --alias %DEV_ORG_ALIAS% ^
                        --instance-url %SFDC_HOST%
                """
            }
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
