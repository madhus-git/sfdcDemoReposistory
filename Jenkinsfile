// ==============================
// Utility Functions
// ==============================
def authenticateOrg() {
    if (isUnix()) {
        sh """
            echo "Authenticating to Salesforce Org: $ORG_ALIAS..."
            sf org login jwt --client-id "$CONNECTED_APP_CONSUMER_KEY" \
                             --jwt-key-file "$JWT_KEY_FILE" \
                             --username "$SFDC_USERNAME" \
                             --alias "$ORG_ALIAS" \
                             --instance-url "$SFDC_HOST"
        """
    } else {
        bat """
            echo Authenticating to Salesforce Org: %ORG_ALIAS%...

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

            def reportDir   = 'code-analyzer-report'
            def htmlReport  = 'StaticAnalysisReport.html'

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

                // --------------------------
                // Install Salesforce CLI + Code Analyzer (v5.x)
                // --------------------------
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

                            echo "Installing Code Analyzer plugin (v5.x)..."
                            sf plugins install code-analyzer || true
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

                            echo Installing Code Analyzer plugin (v5.x)...
                            sf plugins install code-analyzer || exit 0
                        '''
                    }
                }

                // --------------------------
                // Static Code Analysis (Code Analyzer v5.x)
                // --------------------------
                stage('Static Code Analysis') {
                    if (isUnix()) {
                        sh """
                            mkdir -p ${reportDir}
                            sf code-analyzer run --workspace force-app \
                                                 --output-file "${reportDir}/${htmlReport}" || true
                        """
                    } else {
                        bat """
                            if not exist "${reportDir}" mkdir "${reportDir}"
                            sf code-analyzer run --workspace force-app ^
                                                 --output-file "%WORKSPACE%\\${reportDir}\\${htmlReport}" || exit 0
                        """
                    }
                }

                stage('Verify Reports') {
                    if (isUnix()) {
                        sh "ls -l ${reportDir}"
                    } else {
                        bat "dir ${reportDir}"
                    }
                }

                // --------------------------
                // Publish Reports (HTML + assets)
                // --------------------------
                stage('Publish Reports') {
                    // Archive full directory (HTML + CSS + JS)
                    archiveArtifacts artifacts: "${reportDir}/**", fingerprint: true

                    publishHTML(target: [
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: reportDir,
                        reportFiles: htmlReport,
                        reportName: 'Salesforce Code Analyzer Dashboard',
                        reportTitles: 'Salesforce Static Analysis',
                        escapeUnderscores: false
                    ])

                    echo "Salesforce Code Analyzer Dashboard: ${env.BUILD_URL}Salesforce_20Code_20Analyzer_20Dashboard/"
                }

                stage('Authenticate Org') {
                    authenticateOrg()
                }

                stage('Deploy to Org') {
                    deployToOrg()
                }
            }
        }
    } catch (err) {
        echo "Pipeline failed: ${err}"
        currentBuild.result = 'FAILURE'
        throw err
    }
}
