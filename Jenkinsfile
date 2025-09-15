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

            def reportDir   = 'code-analyzer-report'
            def htmlDir     = 'html-report'
            def jsonReport  = 'results.json'
            def htmlReport  = 'index.html'

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
                // Install Salesforce CLI + Code Analyzer v5.x
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

                            echo "Installed plugins:"
                            sf plugins list
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

                            echo Installed plugins:
                            sf plugins list
                        '''
                    }
                }

                // --------------------------
                // Static Code Analysis (Analyzer v5: run + report)
                // --------------------------
                stage('Static Code Analysis') {
    if (isUnix()) {
        sh """
            rm -rf ${reportDir} ${htmlDir}
            mkdir -p ${reportDir} ${htmlDir}

            echo "=== Running Analyzer ==="
            sf code-analyzer run --workspace force-app \
                                 --output-file ${reportDir}/${jsonReport} || true

            echo "=== Generating HTML Report (v5.x) ==="
            if [ -f ${reportDir}/${jsonReport} ]; then
                sf code-analyzer report:html \
                    --input-file ${reportDir}/${jsonReport} \
                    --output-dir ${htmlDir} || true
            fi

            echo "=== Final HTML Report Directory ==="
            ls -R ${htmlDir} || true
        """
    } else {
        bat """
            if exist "${reportDir}" rmdir /s /q "${reportDir}"
            if exist "${htmlDir}" rmdir /s /q "${htmlDir}"
            mkdir "${reportDir}"
            mkdir "${htmlDir}"

            echo === Running Analyzer ===
            sf code-analyzer run --workspace force-app ^
                                 --output-file "%WORKSPACE%\\${reportDir}\\${jsonReport}" || exit 0

            echo === Generating HTML Report (v5.x) ===
            if exist "%WORKSPACE%\\${reportDir}\\${jsonReport}" (
                sf code-analyzer report:html ^
                    --input-file "%WORKSPACE%\\${reportDir}\\${jsonReport}" ^
                    --output-dir "%WORKSPACE%\\${htmlDir}" || echo "Failed to generate HTML"
            )

            echo === Final HTML Report Directory ===
            dir /s "%WORKSPACE%\\${htmlDir}" || echo "No HTML report generated"
        """
    }
}



                // --------------------------
                // Publish Reports (HTML + JSON)
                // --------------------------
                stage('Publish Reports') {
    // Archive artifacts (both JSON + HTML)
    archiveArtifacts artifacts: "${reportDir}/**", fingerprint: true, allowEmptyArchive: true
    archiveArtifacts artifacts: "${htmlDir}/**", fingerprint: true, allowEmptyArchive: true

    // Publish the HTML dashboard in Jenkins
    publishHTML(target: [
        allowMissing: true,   // don't fail if HTML isn't created
        alwaysLinkToLastBuild: true,
        keepAll: true,
        reportDir: htmlDir,
        reportFiles: htmlReport,
        reportName: 'Salesforce Code Analyzer Dashboard',
        reportTitles: 'Salesforce Static Analysis',
        escapeUnderscores: false
    ])

    // Print direct links in Jenkins console
    def analyzerUrl = "${env.BUILD_URL}Salesforce_20Code_20Analyzer_20Dashboard/"
    def indexUrl    = "${analyzerUrl}${htmlReport}"

    echo "Static Analysis Dashboard: ${analyzerUrl}"
    echo "Direct Report Link: ${indexUrl}"
}

                /* stage('Authenticate Org') {
                    authenticateOrg()
                }

                stage('Deploy to Org') {
                    deployToOrg()
                } */
            }
        }
    } catch (err) {
        echo "Pipeline failed: ${err}"
        currentBuild.result = 'FAILURE'
        throw err
    }
}
