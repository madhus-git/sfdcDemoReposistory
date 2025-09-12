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
        withCredentials([
            string(credentialsId: 'sfdc-consumer-key', variable: 'CONNECTED_APP_CONSUMER_KEY'),
            string(credentialsId: 'sfdc-username', variable: 'SFDC_USERNAME'),
            file(credentialsId: 'sfdc-jwt-key', variable: 'JWT_KEY_FILE')
        ]) {

            def SFDC_HOST = 'https://login.salesforce.com'
            def DEV_ORG_ALIAS = 'dev'
            def reportDir = 'pmd-report-html'

            stage('Clean Workspace') {
                cleanWs()
                echo "✅ Workspace cleaned successfully!"
            }

            stage('Checkout Source') {
                checkout scm
            }

            /*stage('Install Prerequisites') {
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
            }*/

            /*stage('Static Code Analysis') {
                echo "🚀 Running PMD analysis on Apex classes..."

                if (isUnix()) {
                    sh """
                        rm -rf "${reportDir}" || true
                        mkdir -p "${reportDir}"

                        npm install --global @salesforce/sfdx-scanner

                        # Generate reports
                        sf scanner run --target "force-app/main/default/classes" --engine pmd --format text --outfile "pmd-report.txt" || echo "No violations found" > "pmd-report.txt"
                        sf scanner run --target "force-app/main/default/classes" --engine pmd --format json --outfile "pmd-report.json" || echo "[]" > "pmd-report.json"

                        # Generate HTML report
                        sf scanner report --input "pmd-report.json" --format html --output "${reportDir}/index.html"

                        # Ensure index.html exists
                        [ ! -f "${reportDir}/index.html" ] && echo "<html><body><h1>No PMD report generated</h1></body></html>" > "${reportDir}/index.html"

                        ls -l pmd-report.*
                        ls -l "${reportDir}"
                    """

                    def criticalCount = sh(script: "grep -o '\"severity\": *\"Critical\"' pmd-report.json | wc -l", returnStdout: true).trim()
                    echo "Critical PMD violations found: ${criticalCount}"
                    if (criticalCount.toInteger() > 0) {
                        error "❌ PMD found ${criticalCount} critical violations!"
                    }

                } else {
                    bat """
                        if exist "${reportDir}" rmdir /s /q "${reportDir}"
                        mkdir "${reportDir}"

                        npm install --global @salesforce/sfdx-scanner

                        REM Run PMD scanner using npx
                        npx sf scanner run --target "force-app/main/default/classes" --engine pmd --format text --outfile "pmd-report.txt"
                        if not exist "pmd-report.txt" echo "No violations found" > "pmd-report.txt"

                        npx sf scanner run --target "force-app/main/default/classes" --engine pmd --format json --outfile "pmd-report.json"
                        if not exist "pmd-report.json" echo [] > "pmd-report.json"

                        REM Generate HTML report
                        npx sf scanner report --input "pmd-report.json" --format html --output "${reportDir}\\index.html"

                        REM Ensure index.html exists
                        if not exist "${reportDir}\\index.html" echo "<html><body><h1>No PMD report generated</h1></body></html>" > "${reportDir}\\index.html"

                        REM Confirm files
                        dir /b pmd-report.*
                        dir /b ${reportDir}

                        timeout /t 2
                    """

                    def criticalCount = powershell(script: """
                        if (Test-Path "pmd-report.json") {
                            (Get-Content "pmd-report.json" | ConvertFrom-Json | Where-Object { \$_.severity -eq 'Critical' }).Count
                        } else { 0 }
                    """, returnStdout: true).trim()
                    echo "Critical PMD violations found: ${criticalCount}"
                    if (criticalCount.isInteger() && criticalCount.toInteger() > 0) {
                        error "❌ PMD found ${criticalCount} critical violations!"
                    }
                }

                archiveArtifacts artifacts: 'pmd-report.*', allowEmptyArchive: true

                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: reportDir,
                    reportFiles: 'index.html',
                    reportName: "PMD Static Analysis Report"
                ])
                echo "✅ PMD analysis completed. HTML report published."
            } */

            /*stage('Authenticate Dev Org') {
                authenticateOrg(DEV_ORG_ALIAS, SFDC_HOST, CONNECTED_APP_CONSUMER_KEY, JWT_KEY_FILE, SFDC_USERNAME)
            }

            stage('Deploy to Dev Org') {
                deployToOrg(DEV_ORG_ALIAS)
            }*/
        }

    } catch (err) {
        echo "❌ Pipeline failed: ${err}"
        currentBuild.result = 'FAILURE'
        throw err
    } finally {
        echo "Pipeline completed."
    }
}
