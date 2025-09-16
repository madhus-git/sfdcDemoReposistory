// ==============================
// Utility Functions
// ==============================
def authenticateOrg() {
    if (isUnix()) {
        sh """
            echo "Authenticating to Salesforce Org: $ORG_ALIAS..."
            sf org login jwt \
                --client-id "$CONNECTED_APP_CONSUMER_KEY" \
                --jwt-key-file "$JWT_KEY_FILE" \
                --username "$SFDC_USERNAME" \
                --alias "$ORG_ALIAS" \
                --instance-url "$SFDC_HOST"
        """
    } else {
        bat """
            echo Authenticating to Salesforce Org: %ORG_ALIAS%
            sf org login jwt ^ 
                --client-id %CONNECTED_APP_CONSUMER_KEY% ^ 
                --jwt-key-file %JWT_KEY_FILE% ^ 
                --username %SFDC_USERNAME% ^ 
                --alias %ORG_ALIAS% ^ 
                --instance-url %SFDC_HOST%
        """
    }
}

def deployToOrg() {
    if (isUnix()) {
        sh "sf project deploy start --target-org $ORG_ALIAS --ignore-conflicts --wait 10"
    } else {
        bat "sf project deploy start --target-org %ORG_ALIAS% --ignore-conflicts --wait 10"
    }
}

// ==============================
// Main Pipeline
// ==============================
node {
    try {
        withCredentials([
            string(credentialsId: 'sfdc-consumer-key', variable: 'CONNECTED_APP_CONSUMER_KEY'),
            string(credentialsId: 'sfdc-username', variable: 'SFDC_USERNAME'),
            file(credentialsId: 'sfdc-jwt-key', variable: 'JWT_KEY_FILE')
        ]) {

            withEnv([
                "SFDC_HOST=https://login.salesforce.com",
                "ORG_ALIAS=projectdemosfdc"
            ]) {

                stage('Clean Workspace') {
                    cleanWs()
                    echo "Workspace cleaned successfully!"
                }

                stage('Checkout Source') {
                    checkout scm
                }

                stage('Install Prerequisites') {
                    if (isUnix()) {
                        sh '''
                            if ! command -v sf >/dev/null 2>&1; then
                                echo "Installing Salesforce CLI..."
                                npm install --global @salesforce/cli
                            else
                                echo "Salesforce CLI already installed."
                            fi

                            sf plugins install @salesforce/sfdx-scanner || echo "Plugin already installed"
                            sf plugins update @salesforce/sfdx-scanner
                        '''
                    } else {
                        bat '''
                            where sf >nul 2>nul
                            if %ERRORLEVEL% neq 0 (
                                echo Installing Salesforce CLI...
                                npm install --global @salesforce/cli
                            ) else (
                                echo Salesforce CLI already installed.
                            )

                            sf plugins install @salesforce/sfdx-scanner || echo Plugin already installed
                            sf plugins update @salesforce/sfdx-scanner
                        '''
                    }
                }

                stage('Static Code Analysis & Publish') {
                    def htmlDir    = 'html-report'
                    def htmlReport = 'CodeAnalyzerReport.html'

                    if (isUnix()) {
                        sh """
                            rm -rf ${htmlDir}
                            mkdir -p ${htmlDir}

                            echo "=== Running Salesforce Code Analyzer ==="
                            sf code-analyzer run --workspace force-app --rule-selector Recommended --output-file ${htmlDir}/${htmlReport}

                            if [ ! -f ${htmlDir}/${htmlReport} ]; then
                                echo "HTML report generation failed!"
                                exit 1
                            fi
                        """
                    } else {
                        bat """
                            if exist "${htmlDir}" rmdir /s /q "${htmlDir}"
                            mkdir "${htmlDir}"

                            echo === Running Salesforce Code Analyzer ===
                            sf code-analyzer run --workspace force-app --rule-selector Recommended --output-file "%WORKSPACE%\\${htmlDir}\\${htmlReport}"

                            if not exist "%WORKSPACE%\\${htmlDir}\\${htmlReport}" (
                                echo HTML report generation failed!
                                exit /b 1
                            )
                        """
                    }

                    // Archive all report assets
                    archiveArtifacts artifacts: "${htmlDir}/**", fingerprint: true

                    // ============================
                    // FIX: Allow JS & CSS in HTML report
                    // ============================
                    System.setProperty(
                        "hudson.model.DirectoryBrowserSupport.CSP",
                        "sandbox allow-same-origin allow-scripts; default-src 'self'; script-src * 'unsafe-eval'; img-src *; style-src * 'unsafe-inline'; font-src *"
                    )

                    // Publish HTML report
                    publishHTML(target: [
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: htmlDir,
                        reportFiles: htmlReport,
                        reportName: 'Salesforce Code Analyzer Report',
                        reportTitles: 'Static Code Analysis HTML'
                    ])
                }

                // ------------------------------
                // Optional: Authenticate & Deploy
                // ------------------------------
                /*
                stage('Authenticate Org') {
                    authenticateOrg()
                }

                stage('Deploy to Org') {
                    deployToOrg()
                }
                */
            }
        }
    } catch (err) {
        echo "Pipeline failed: ${err}"
        currentBuild.result = 'FAILURE'
        throw err
    }
}
