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

                stage('Static Code Analysis & Publish (Debug)') {
                    if (isUnix()) {
                        sh """
                            rm -rf ${reportDir} ${htmlDir}
                            mkdir -p ${reportDir} ${htmlDir}

                            echo "=== Running Analyzer ==="
                            sf code-analyzer run --workspace force-app \\
                                                 --output-file ${reportDir}/${jsonReport} || true

                            echo "=== Checking JSON results ==="
                            ls -l ${reportDir}

                            echo "=== Generating HTML Report (v5.x) ==="
                            if [ -f ${reportDir}/${jsonReport} ]; then
                                sf code-analyzer report:html \\
                                    --input-file ${reportDir}/${jsonReport} \\
                                    --output-dir ${htmlDir} || echo "Failed to generate HTML report"
                            else
                                echo "JSON report not found, skipping HTML generation"
                            fi

                            echo "=== Final HTML Report Directory ==="
                            ls -R ${htmlDir} || echo "No HTML report generated"
                        """

                        // Detect HTML file dynamically
                        env.HTML_FILE = sh(
                            script: "ls ${htmlDir}/*.html 2>/dev/null | head -n 1 | xargs -n1 basename || true",
                            returnStdout: true
                        ).trim()

                    } else {
                        bat """
                            if exist "${reportDir}" rmdir /s /q "${reportDir}"
                            if exist "${htmlDir}" rmdir /s /q "${htmlDir}"
                            mkdir "${reportDir}"
                            mkdir "${htmlDir}"

                            echo === Running Analyzer ===
                            sf code-analyzer run --workspace force-app ^
                                                 --output-file "%WORKSPACE%\\${reportDir}\\${jsonReport}" || exit 0

                            echo === Checking JSON results ===
                            dir "%WORKSPACE%\\${reportDir}"

                            echo === Generating HTML Report (v5.x) ===
                            if exist "%WORKSPACE%\\${reportDir}\\${jsonReport}" (
                                sf code-analyzer report:html ^
                                    --input-file "%WORKSPACE%\\${reportDir}\\${jsonReport}" ^
                                    --output-dir "%WORKSPACE%\\${htmlDir}" || echo "Failed to generate HTML report"
                            ) else (
                                echo JSON report not found, skipping HTML generation
                            )

                            echo === Final HTML Report Directory ===
                            dir /s "%WORKSPACE%\\${htmlDir}" || echo "No HTML report generated"

                            REM Detect HTML file dynamically
                            for %%f in (${htmlDir}\\*.html) do @echo %%~nxf
                        """

                        // Use first found HTML file for publishing
                        env.HTML_FILE = bat(
                            script: "for %%f in (${htmlDir}\\*.html) do @echo %%~nxf & goto :done\n:done",
                            returnStdout: true
                        ).trim()
                    }

                    if (env.HTML_FILE) {
                        echo "✅ Detected HTML report file: ${env.HTML_FILE}"

                        archiveArtifacts artifacts: "${reportDir}/**", fingerprint: true, allowEmptyArchive: true
                        archiveArtifacts artifacts: "${htmlDir}/**", fingerprint: true, allowEmptyArchive: true

                        publishHTML(target: [
                            allowMissing: true,
                            alwaysLinkToLastBuild: true,
                            keepAll: true,
                            reportDir: htmlDir,
                            reportFiles: env.HTML_FILE,
                            reportName: 'Salesforce Code Analyzer Dashboard',
                            reportTitles: 'Salesforce Static Analysis',
                            escapeUnderscores: false
                        ])

                        echo "📊 Static Analysis Dashboard: ${env.BUILD_URL}Salesforce_20Code_20Analyzer_20Dashboard/"
                        echo "🔗 Direct Report Link: ${env.BUILD_URL}Salesforce_20Code_20Analyzer_20Dashboard/${env.HTML_FILE}"
                    } else {
                        echo "⚠️ No HTML report generated, skipping publishHTML."
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
