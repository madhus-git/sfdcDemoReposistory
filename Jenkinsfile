// ------------------------
// Utility Functions
// ------------------------
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

// ------------------------
// Pipeline
// ------------------------
node {
    try {
        // ---------------------
        // Global Credentials
        // ---------------------
        withCredentials([
            string(credentialsId: 'sfdc-consumer-key', variable: 'CONNECTED_APP_CONSUMER_KEY'),
            string(credentialsId: 'sfdc-username', variable: 'SFDC_USERNAME'),
            file(credentialsId: 'sfdc-jwt-key', variable: 'JWT_KEY_FILE')
        ]) {
            def SFDC_HOST = 'https://login.salesforce.com'
            def DEV_ORG_ALIAS = 'dev'
            def workspace = pwd()

            // ---------------------
            // Pipeline Stages
            // ---------------------
            stage('Clean Workspace') {
                cleanWs()
                echo "✅ Workspace cleaned successfully!"
            }

            stage('Checkout Source') {
                checkout scm
            }

            stage('Install Prerequisites') {
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

            stage('Static Code Analysis') {
                echo "Running PMD analysis on Apex classes..."
                if (isUnix()) {
                    sh """
                        npm install --global @salesforce/sfdx-scanner

                        sf scanner run --target "force-app/main/default/classes" --engine pmd --format text --outfile "${workspace}/pmd-report.txt" || echo "No violations found" > "${workspace}/pmd-report.txt"
                        sf scanner run --target "force-app/main/default/classes" --engine pmd --format json --outfile "${workspace}/pmd-report.json" || echo "[]" > "${workspace}/pmd-report.json"

                        [ ! -f "${workspace}/pmd-report.txt" ] && echo "No violations found" > "${workspace}/pmd-report.txt"
                        [ ! -f "${workspace}/pmd-report.json" ] && echo "[]" > "${workspace}/pmd-report.json"

                        ls -l "${workspace}/pmd-report.*"
                    """
                    def criticalCount = sh(script: "grep -o '\"severity\": *\"Critical\"' ${workspace}/pmd-report.json | wc -l", returnStdout: true).trim()
                    if (criticalCount.toInteger() > 0) {
                        error "❌ PMD found ${criticalCount} critical violations! Check pmd-report.json"
                    }
                } else {
                    bat """
                        npm install --global @salesforce/sfdx-scanner

                        sf scanner run --target "force-app/main/default/classes" --engine pmd --format text --outfile "${workspace}\\pmd-report.txt"
                        if not exist "${workspace}\\pmd-report.txt" echo No violations found > "${workspace}\\pmd-report.txt"

                        sf scanner run --target "force-app/main/default/classes" --engine pmd --format json --outfile "${workspace}\\pmd-report.json"
                        if not exist "${workspace}\\pmd-report.json" echo [] > "${workspace}\\pmd-report.json"

                        dir /b "${workspace}\\pmd-report.*"
                    """
                    def criticalCount = powershell(script: """
                        if (Test-Path "${workspace}\\pmd-report.json") {
                            (Get-Content "${workspace}\\pmd-report.json" | ConvertFrom-Json | Where-Object { \$_.severity -eq 'Critical' }).Count
                        } else { 0 }
                    """, returnStdout: true).trim()
                    if (criticalCount.isInteger() && criticalCount.toInteger() > 0) {
                        error "❌ PMD found ${criticalCount} critical violations! Check pmd-report.json"
                    }
                }
                archiveArtifacts artifacts: "${workspace}/pmd-report.*", allowEmptyArchive: true
            }

            stage('Authenticate Dev Org') {
                authenticateOrg(DEV_ORG_ALIAS, SFDC_HOST, CONNECTED_APP_CONSUMER_KEY, JWT_KEY_FILE, SFDC_USERNAME)
            }

            stage('Deploy to Dev Org') {
                deployToOrg(DEV_ORG_ALIAS)
            }

        } // end withCredentials

    } catch (err) {
        echo "❌ Pipeline failed: ${err}"
        currentBuild.result = 'FAILURE'
        throw err
    } finally {
        echo "Pipeline completed."
    }
}
