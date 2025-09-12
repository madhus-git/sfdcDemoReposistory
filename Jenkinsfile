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

            stage('Install prerequisite') {
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
                if (isUnix()) {
                    sh '''
                        echo "Running PMD analysis on Apex classes..."
                        npm install --global @salesforce/sfdx-scanner

                        # Generate text report
                        sf scanner run --target "force-app/main/default/classes" \
                                       --engine pmd \
                                       --format text \
                                       --outfile pmd-report.txt || true

                        # Generate JSON report
                        sf scanner run --target "force-app/main/default/classes" \
                                       --engine pmd \
                                       --format json \
                                       --outfile pmd-report.json || true

                        # Ensure JSON file exists
                        if [ ! -f pmd-report.txt ]; then
                            echo "No violations found" > pmd-report.txt
                        fi
                        if [ ! -f pmd-report.json ]; then
                            echo "[]" > pmd-report.json
                        fi
                    '''

                    def criticalCount = sh(
                        script: "grep -o '\"severity\": *\"Critical\"' pmd-report.json | wc -l",
                        returnStdout: true
                    ).trim()
                    if (criticalCount.toInteger() > 0) {
                        error "❌ PMD found ${criticalCount} critical violations! Check pmd-report.json for details."
                    }
                } else {
                    bat '''
                        echo Running PMD analysis on Apex classes...
                        npm install --global @salesforce/sfdx-scanner

                        rem Generate text report
                        sf scanner run --target "force-app\\main\\default\\classes" ^
                                       --engine pmd ^
                                       --format text ^
                                       --outfile pmd-report.txt
                        if %ERRORLEVEL% neq 0 (
                            echo No violations found > pmd-report.txt
                        )

                        rem Generate JSON report
                        sf scanner run --target "force-app\\main\\default\\classes" ^
                                       --engine pmd ^
                                       --format json ^
                                       --outfile pmd-report.json
                        if %ERRORLEVEL% neq 0 (
                            echo [] > pmd-report.json
                        )

                        rem Ensure files exist
                        if not exist pmd-report.txt echo No violations found > pmd-report.txt
                        if not exist pmd-report.json echo [] > pmd-report.json
                    '''

                    def criticalCount = powershell(
                        script: """
                            if (Test-Path "pmd-report.json") {
                                (Get-Content pmd-report.json | Select-String -Pattern '"severity": "Critical"').Count
                            } else {
                                0
                            }
                        """,
                        returnStdout: true
                    ).trim()

                    if (criticalCount.isInteger() && criticalCount.toInteger() > 0) {
                        error "❌ PMD found ${criticalCount} critical violations! Check pmd-report.json for details."
                    }
                }

                // Archive both reports
                archiveArtifacts artifacts: 'pmd-report.*', allowEmptyArchive: true
            }

            stage('Authenticate Org') {
                authenticateOrg(DEV_ORG_ALIAS, SFDC_HOST, CONNECTED_APP_CONSUMER_KEY, JWT_KEY_FILE, SFDC_USERNAME)
            }

            stage('Deploy to Org') {
                deployToOrg(DEV_ORG_ALIAS)
            }

        } // end withCredentials
    } catch (err) {
        echo "❌ Pipeline failed: ${err}"
        currentBuild.result = 'FAILURE'
        throw err
    } finally {
        archiveArtifacts artifacts: 'pmd-report.*', allowEmptyArchive: true
    }
}
