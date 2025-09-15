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

            def reportDir   = 'code-analyzer-report'   // JSON output
            def htmlDir     = 'html-report'            // HTML + assets output
            def jsonReport  = 'results.json'
            def mainHtml    = 'index.html'

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
                stage('Install Prerequisites') {
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
                // Static Code Analysis (Analyzer v5 + HTML Report)
                // --------------------------
                stage('Static Code Analysis') {
                    if (isUnix()) {
                        sh """
                            rm -rf ${reportDir} ${htmlDir}
                            mkdir -p ${reportDir} ${htmlDir}

                            # Run analysis to JSON
                            sf code-analyzer run --workspace force-app \
                                                 --output-file ${reportDir}/${jsonReport} || true

                            # Generate styled HTML report
                            if [ -f ${reportDir}/${jsonReport} ]; then
                                sf code-analyzer report --input-file ${reportDir}/${jsonReport} \
                                                        --format html \
                                                        --output-dir ${htmlDir} || true
                            else
                                echo "JSON report not found, skipping HTML report generation"
                            fi

                            echo "Generated report files:"
                            ls -R ${htmlDir}
                        """
                    } else {
                        bat """
                            if exist "${reportDir}" rmdir /s /q "${reportDir}"
                            if exist "${htmlDir}" rmdir /s /q "${htmlDir}"
                            mkdir "${reportDir}"
                            mkdir "${htmlDir}"

                            REM Run analysis to JSON
                            sf code-analyzer run --workspace force-app ^
                                                 --output-file "%WORKSPACE%\\${reportDir}\\${jsonReport}" || exit 0

                            REM Generate styled HTML report
                            if exist "%WORKSPACE%\\${reportDir}\\${jsonReport}" (
                                sf code-analyzer report --input-file "%WORKSPACE%\\${reportDir}\\${jsonReport}" ^
                                                        --format html ^
                                                        --output-dir "%WORKSPACE%\\${htmlDir}" || exit 0
                            ) else (
                                echo JSON report not found, skipping HTML report generation
                            )

                            echo Generated report files:
                            dir /s "%WORKSPACE%\\${htmlDir}"
                        """
                    }
                }

                // --------------------------
                // Publish Reports (HTML + Assets)
                // --------------------------
                stage('Publish Reports') {
                    // Verify folder contents before publishing
                    if (isUnix()) {
                        sh "ls -R ${htmlDir}"
                    } else {
                        bat "dir /s ${htmlDir}"
                    }

                    // Archive JSON + HTML reports
                    archiveArtifacts artifacts: "${reportDir}/**", fingerprint: true
                    archiveArtifacts artifacts: "${htmlDir}/**", fingerprint: true

                    // Publish HTML report in Jenkins
                    publishHTML(target: [
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: htmlDir,       // Folder with index.html + assets
                        reportFiles: mainHtml,    // Main entry HTML file
                        reportName: 'Salesforce Code Analyzer Dashboard',
                        reportTitles: 'Salesforce Static Analysis',
                        escapeUnderscores: false
                    ])

                    echo "Static Analysis report available in Jenkins UI: ${env.BUILD_URL}Salesforce_20Code_20Analyzer_20Dashboard/"
                }

                // --------------------------
                // Deploy
                // --------------------------
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
