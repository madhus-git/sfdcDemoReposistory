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

            //def reportDir   = 'code-analyzer-report'
            //def htmlDir     = 'html-report'
            //def jsonReport  = 'results.json'
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

                // ==============================
// Static Code Analysis & Publish
// ==============================
stage('Static Code Analysis & Publish') {
    def reportDir  = 'code-analyzer-report'
    def htmlDir    = 'html-report'
    def jsonReport = 'results.json'

    if (isUnix()) {
        sh """
            # Clean previous reports
            rm -rf ${reportDir} ${htmlDir}
            mkdir -p ${reportDir} ${htmlDir}

            echo "=== Running Salesforce Code Analyzer ==="
            sf code-analyzer run --workspace force-app --output-file ${reportDir}/${jsonReport}
            
            # Check if JSON report exists
            if [ ! -f ${reportDir}/${jsonReport} ]; then
                echo "❌ JSON report not generated. Check analyzer logs."
                exit 1
            fi

            echo "=== JSON Report Generated ==="
            ls -l ${reportDir}

            echo "=== Generating HTML Report ==="
            sf code-analyzer report:html --input-file ${reportDir}/${jsonReport} --output-dir ${htmlDir} --force

            # Verify HTML report
            if [ ! -d ${htmlDir} ] || [ -z "\$(ls -A ${htmlDir})" ]; then
                echo "❌ HTML report generation failed."
                exit 1
            fi

            echo "=== HTML Report Generated ==="
            ls -R ${htmlDir}
        """

        // Detect HTML file dynamically
        env.HTML_FILE = sh(script: "find ${htmlDir} -name '*.html' | head -n1 | xargs -n1 basename", returnStdout: true).trim()

    } else {
        bat """
            REM Clean previous reports
            if exist "${reportDir}" rmdir /s /q "${reportDir}"
            if exist "${htmlDir}" rmdir /s /q "${htmlDir}"
            mkdir "${reportDir}"
            mkdir "${htmlDir}"

            echo === Running Salesforce Code Analyzer ===
            sf code-analyzer run --workspace force-app --output-file "%WORKSPACE%\\${reportDir}\\${jsonReport}"
            
            REM Check if JSON report exists
            if not exist "%WORKSPACE%\\${reportDir}\\${jsonReport}" (
                echo ❌ JSON report not generated. Check analyzer logs.
                exit /b 1
            )

            echo === JSON Report Generated ===
            dir "%WORKSPACE%\\${reportDir}"

            echo === Generating HTML Report ===
            sf code-analyzer report:html --input-file "%WORKSPACE%\\${reportDir}\\${jsonReport}" --output-dir "%WORKSPACE%\\${htmlDir}" --force

            REM Verify HTML report
            if not exist "%WORKSPACE%\\${htmlDir}\\*.html" (
                echo ❌ HTML report generation failed.
                exit /b 1
            )

            echo === HTML Report Generated ===
            dir /s "%WORKSPACE%\\${htmlDir}"
        """

        // Detect HTML file dynamically
        env.HTML_FILE = bat(
    script: """powershell -Command "Get-ChildItem -Path '${htmlDir}' -Filter '*.html' | Select-Object -First 1 | ForEach-Object { \$_.Name }" """,
    returnStdout: true
).trim()
    }

    // --------------------------
    // Publish Reports to Jenkins
    // --------------------------
    if (env.HTML_FILE) {
        echo "✅ Detected HTML report file: ${env.HTML_FILE}"

        // Archive JSON & HTML reports
        archiveArtifacts artifacts: "${reportDir}/**", fingerprint: true
        archiveArtifacts artifacts: "${htmlDir}/**", fingerprint: true

        // Publish HTML report
        publishHTML(target: [
            allowMissing: false,
            alwaysLinkToLastBuild: true,
            keepAll: true,
            reportDir: htmlDir,
            reportFiles: '*.html',
            reportName: 'Salesforce Code Analyzer Dashboard',
            reportTitles: 'Salesforce Static Analysis',
            escapeUnderscores: false
        ])

        echo "📊 Static Analysis Dashboard: ${env.BUILD_URL}Salesforce_20Code_20Analyzer_20Dashboard/"
    } else {
        error "❌ No HTML report generated, cannot publish to Jenkins."
    }
}


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
