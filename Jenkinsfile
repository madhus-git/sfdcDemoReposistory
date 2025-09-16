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

            // Clean Workspace
            stage('Clean Workspace') {
                cleanWs()
                echo "Workspace cleaned successfully!"
            }

            // Checkout Source
            stage('Checkout Source') {
                checkout scm
            }

            // Install Salesforce CLI & Code Analyzer
            stage('Install Prerequisites') {
                if (isUnix()) {
                    sh '''
                        # Install Salesforce CLI if not present
                        if ! command -v sf >/dev/null 2>&1; then
                            echo "Installing Salesforce CLI..."
                            npm install --global @salesforce/cli
                        else
                            echo "Salesforce CLI already installed."
                        fi

                        # Install/Update Code Analyzer plugin (sfdx-scanner)
                        sf plugins install @salesforce/sfdx-scanner || echo "Plugin already installed"
                        sf plugins update @salesforce/sfdx-scanner
                        sf plugins list
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

                            echo Installing/Updating Code Analyzer plugin (sfdx-scanner)...
                            sf plugins install @salesforce/sfdx-scanner || echo Plugin already installed
                            sf plugins update @salesforce/sfdx-scanner
                            sf plugins list
                        '''
                    }
            }

            // Static Code Analysis & Publish
            stage('Static Code Analysis & Publish') {
                def htmlDir    = 'html-report'
                def htmlReport = 'CodeAnalyzerReport.html'

                if (isUnix()) {
                    sh """
                        rm -rf ${htmlDir}
                        mkdir -p ${htmlDir}

                        echo "=== Running Salesforce Code Analyzer (HTML Direct) ==="
                        sf code-analyzer run --workspace force-app --rule-selector Recommended --output-file ${htmlDir}/${htmlReport}

                        if [ ! -f ${htmlDir}/${htmlReport} ]; then
                            echo "HTML report generation failed!"
                            exit 1
                        fi

                        echo "HTML Report Generated Successfully"
                        ls -l ${htmlDir}
                    """
                } else {
                    bat """
                        if exist "${htmlDir}" rmdir /s /q "${htmlDir}"
                        mkdir "${htmlDir}"

                        echo === Running Salesforce Code Analyzer (HTML Direct) ===
                        sf code-analyzer run --workspace force-app --rule-selector Recommended --output-file "%WORKSPACE%\\${htmlDir}\\${htmlReport}"

                        if not exist "%WORKSPACE%\\${htmlDir}\\${htmlReport}" (
                            echo HTML report generation failed!
                                exit /b 1
                        )

                        echo HTML Report Generated Successfully
                        dir "%WORKSPACE%\\${htmlDir}"
                    """
                }

                archiveArtifacts artifacts: "${htmlDir}/**", fingerprint: true

                publishHTML(target: [
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: htmlDir,
                    reportFiles: htmlReport,
                    reportName: 'Salesforce Code Analyzer v5 Report',
                    reportTitles: 'Static Code Analysis HTML'
                ])
            }

            // Authenticate Org
            /*stage('Authenticate Org') {
                    authenticateOrg()
            }

            // Deploy to Org
            stage('Deploy to Org') {
                deployToOrg()
            }*/
        }
    }
} catch (err) {
    echo "Pipeline failed: ${err}"
    currentBuild.result = 'FAILURE'
    throw err
}
}
