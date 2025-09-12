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
            def reportDir = "${workspace}/pmd-report-html"

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
                echo "🚀 Running PMD analysis on Apex classes..."

                if (isUnix()) {
                    sh """
                        mkdir -p "${reportDir}"
                        npm install --global @salesforce/sfdx-scanner

                        echo Generating PMD reports...
                        sf scanner run --target "force-app/main/default/classes" --engine pmd --format text --outfile "${workspace}/pmd-report.txt" || echo "No violations found" > "${workspace}/pmd-report.txt"
                        sf scanner run --target "force-app/main/default/classes" --engine pmd --format json --outfile "${workspace}/pmd-report.json" || echo "[]" > "${workspace}/pmd-report.json"

                        echo Generating HTML report...
                        sf scanner report --input "${workspace}/pmd-report.json" --format html --output "${reportDir}/index.html"

                        echo Listing generated files...
                        ls -l "${workspace}/pmd-report.*"
                        ls -l "${reportDir}"
                    """
                    def criticalCount = sh(script: "grep -o '\"severity\": *\"Critical\"' ${workspace}/pmd-report.json | wc -l", returnStdout: true).trim()
                    echo "Critical PMD violations found: ${criticalCount}"
                    if (criticalCount.toInteger() > 0) {
                        error "❌ PMD found ${criticalCount} critical violations!"
                    }
                } else {
                    bat """
                        mkdir "${reportDir}"
                        npm install --global @salesforce/sfdx-scanner

                        echo Generating PMD reports...
                        sf scanner run --target "force-app/main/default/classes" --engine pmd --format text --outfile "${workspace}\\pmd-report.txt"
                        if not exist "${workspace}\\pmd-report.txt" echo No violations found > "${workspace}\\pmd-report.txt"

                        sf scanner run --target "force-app/main/default/classes" --engine pmd --format json --outfile "${workspace}\\pmd-report.json"
                        if not exist "${workspace}\\pmd-report.json" echo [] > "${workspace}\\pmd-report.json"

                        echo Generating HTML report...
                        sf scanner report --input "${workspace}\\pmd-report.json" --format html --output "${reportDir}\\index.html"

                        echo Listing generated files...
                        dir /b "${workspace}\\pmd-report.*"
                        dir /b "${reportDir}"
                    """
                    def criticalCount = powershell(script: """
                        if (Test-Path "${workspace}\\pmd-report.json") {
                            (Get-Content "${workspace}\\pmd-report.json" | ConvertFrom-Json | Where-Object { \$_.severity -eq 'Critical' }).Count
                        } else { 0 }
                    """, returnStdout: true).trim()
                    echo "Critical PMD violations found: ${criticalCount}"
                    if (criticalCount.isInteger() && criticalCount.toInteger() > 0) {
                        error "❌ PMD found ${criticalCount} critical violations!"
                    }
                }

                // Archive artifacts
                archiveArtifacts artifacts: "${workspace}/pmd-report.*", allowEmptyArchive: true

                // Publish HTML report in Jenkins UI
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: "${reportDir}",
                    reportFiles: 'index.html',
                    reportName: "PMD Static Analysis Report"
                ])

                echo "✅ PMD analysis completed. HTML report published."
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
