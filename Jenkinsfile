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
            def SFDC_HOST = 'https://login.salesforce.com'
            def DEV_ORG_ALIAS = 'projectdemosfdc'

            stage('Clean Workspace') {
                cleanWs()
                echo "Workspace cleaned successfully!"
            }

            stage('Checkout Source') {
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

            // -------------------------------
            // Static Code Analysis (PMD)
            // -------------------------------
            stage('Static Code Analysis - PMD') {
                if (isUnix()) {
                    sh '''
                        echo "Running PMD analysis on Apex classes..."
                        npm install --global @salesforce/sfdx-scanner
                        # Generate both text and JSON reports
                        sf scanner run --target "force-app/main/default/classes" \
                                       --engine pmd \
                                       --format text \
                                       --outfile pmd-report.txt || true

                        sf scanner run --target "force-app/main/default/classes" \
                                       --engine pmd \
                                       --format json \
                                       --outfile pmd-report.json || true
                    '''
                    // Fail only on critical violations in JSON
                    def criticalCount = sh(script: "grep -o '\"severity\": *\"Critical\"' pmd-report.json | wc -l", returnStdout: true).trim()
                    if (criticalCount.toInteger() > 0) {
                        error "❌ PMD found ${criticalCount} critical violations! Check pmd-report.json for details."
                    }
                } else {
                    bat '''
                        echo Running PMD analysis on Apex classes...
                        npm install --global @salesforce/sfdx-scanner
                        rem Generate both text and JSON reports
                        sf scanner run --target "force-app\\main\\default\\classes" ^
                                       --engine pmd ^
                                       --format text ^
                                       --outfile pmd-report.txt || exit /b 0

                        sf scanner run --target "force-app\\main\\default\\classes" ^
                                       --engine pmd ^
                                       --format json ^
                                       --outfile pmd-report.json || exit /b 0
                    '''
                    // Fail only on critical violations
                    def criticalCount = bat(script: 'findstr /i \\"severity\\":\\"Critical\\" pmd-report.json | find /c /v ""', returnStdout: true).trim()
                    if (criticalCount.isInteger() && criticalCount.toInteger() > 0) {
                        error "❌ PMD found ${criticalCount} critical violations! Check pmd-report.json for details."
                    }
                }

                // Archive reports
                archiveArtifacts artifacts: 'pmd-report.*', allowEmptyArchive: true
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
    }
}
