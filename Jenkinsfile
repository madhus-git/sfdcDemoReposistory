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
            sf org login jwt --client-id %CONNECTED_APP_CONSUMER_KEY% ^
                             --jwt-key-file %JWT_KEY_FILE% ^
                             --username %SFDC_USERNAME% ^
                             --alias ${orgAlias} ^
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
    try {
        // Global Credentials
        withCredentials([
            string(credentialsId: 'sfdc-consumer-key', variable: 'CONNECTED_APP_CONSUMER_KEY'),
            string(credentialsId: 'sfdc-username', variable: 'SFDC_USERNAME'),
            file(credentialsId: 'sfdc-jwt-key', variable: 'JWT_KEY_FILE')
        ]) {
            // Global Environment Variables
            def SFDC_HOST = 'https://login.salesforce.com'
            def DEV_ORG_ALIAS = 'projectdemosfdc'

            // ---------------------
            // Pipeline Stages
            // ---------------------

            stage('Clean Workspace') {
                cleanWs()
                echo "Workspace cleaned successfully!"
            }

            stage('Checkout Source') {
                checkout scm
            }

            stage('Static Code Analysis') {
                echo "Running PMD static code analysis on Apex classes..."
                if (isUnix()) {
                    sh '''
                        if [ ! -d "pmd-bin" ]; then
                            echo "Downloading PMD 7.16.0..."
                            wget -q "https://github.com/pmd/pmd/releases/download/pmd_releases%2F7.16.0/pmd-dist-7.16.0-bin.zip" -O pmd.zip
                            unzip -q pmd.zip
                            mv pmd-bin-7.16.0 pmd-bin
                        fi

                        ./pmd-bin/bin/pmd check \
                            -d force-app/main/default/classes \
                            -R category/apex/design.xml \
                            -f text > pmd-report.txt || true

                        echo "PMD Report Generated:"
                        cat pmd-report.txt
                    '''
                } else {
                    bat '''
                        if not exist "%WORKSPACE%\\pmd-bin" (
                            echo Downloading PMD 7.16.0...
                            curl -L -o "%WORKSPACE%\\pmd.zip" "https://github.com/pmd/pmd/releases/download/pmd_releases%2F7.16.0/pmd-dist-7.16.0-bin.zip"
                            powershell -command "Expand-Archive -Force '%WORKSPACE%\\pmd.zip' '%WORKSPACE%'"
                            ren "%WORKSPACE%\\pmd-bin-7.16.0" pmd-bin
                        )

                        echo Running PMD Analysis...
                        call "%WORKSPACE%\\pmd-bin\\bin\\pmd.bat" check ^
                            -d "%WORKSPACE%\\force-app\\main\\default\\classes" ^
                            -R category/apex/design.xml ^
                            -f text > "%WORKSPACE%\\pmd-report.txt" || exit /b 0

                        type "%WORKSPACE%\\pmd-report.txt"
                    '''
                }
            }

            stage('Install Prerequisite') {
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
                authenticateOrg(DEV_ORG_ALIAS, SFDC_HOST, CONNECTED_APP_CONSUMER_KEY, JWT_KEY_FILE, SFDC_USERNAME)
            }

            stage('Deploy to Org') { 
                deployToOrg(DEV_ORG_ALIAS)
            }

        } // end of withCredentials
    } catch (err) {
        echo "❌ Pipeline failed: ${err}"
        currentBuild.result = 'FAILURE'
        throw err
    } finally {
        // Always archive PMD report if generated
        archiveArtifacts artifacts: 'pmd-report.txt', onlyIfSuccessful: false
    }
}
