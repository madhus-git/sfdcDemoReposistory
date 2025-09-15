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
            def jsonReport  = 'results.json'
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
                            )

                            echo Installing Code Analyzer plugin (v5.x)...
                            sf plugins install code-analyzer || exit 0
                        '''
                    }
                }

                // --------------------------
                // Static Code Analysis (Analyzer v5 + Styled Report)
                // --------------------------
                stage('Static Code Analysis') {
                    if (isUnix()) {
                        sh """
                            rm -rf ${reportDir}
                            mkdir -p ${reportDir}

                            # Step 1: Run analysis to JSON
                            sf code-analyzer run --workspace force-app \
                                                 --output-file ${reportDir}/${jsonReport} --json || true

                            # Step 2: Generate styled HTML report (with CSS + JS)
                            sf code-analyzer report --input-file ${reportDir}/${jsonReport} \
                                                    --format html \
                                                    --output-dir ${reportDir}
                        """
                    } else {
                        bat """
                            if exist "${reportDir}" rmdir /s /q "${reportDir}"
                            mkdir "${reportDir}"

                            REM Step 1: Run analysis to JSON
                            sf code-analyzer run --workspace force-app ^
                                                 --output-file "%WORKSPACE%\\${reportDir}\\${jsonReport}" --json || exit 0

                            REM Step 2: Generate styled HTML report
                            sf code-analyzer report --input-file "%WORKSPACE%\\${reportDir}\\${jsonReport}" ^
                                                    --format html ^
                                                    --output-dir "%WORKSPACE%\\${reportDir}"
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
