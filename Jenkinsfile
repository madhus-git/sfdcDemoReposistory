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
                                echo "Salesforce CLI not found, installing..."
                                npm install --global @salesforce/cli
                            fi

                            echo "Installing Salesforce Code Analyzer v5..."
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

                            echo Installing Salesforce Code Analyzer v5...
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
            rm -rf ${reportDir} ${htmlDir}
            mkdir -p ${reportDir} ${htmlDir}

            echo "=== Running Salesforce Code Analyzer v5 (JSON) ==="
            sf code-analyzer run --workspace force-app --rule-selector Recommended --output-file ${reportDir}/${jsonReport}

            echo "=== Generating HTML Report from JSON ==="
            sf code-analyzer report html --input-file ${reportDir}/${jsonReport} --output-dir ${htmlDir}

            echo "=== Reports Generated ==="
            ls -l ${reportDir}
            ls -l ${htmlDir}
        """
    } else {
        bat """
            if exist "${reportDir}" rmdir /s /q "${reportDir}"
            if exist "${htmlDir}" rmdir /s /q "${htmlDir}"
            mkdir "${reportDir}"
            mkdir "${htmlDir}"

            echo === Running Salesforce Code Analyzer v5 (JSON) ===
            sf code-analyzer run --workspace force-app --rule-selector Recommended --output-file "%WORKSPACE%\\${reportDir}\\${jsonReport}"

            echo === Generating HTML Report from JSON ===
            sf code-analyzer report html --input-file "%WORKSPACE%\\${reportDir}\\${jsonReport}" --output-dir "%WORKSPACE%\\${htmlDir}"

            echo === Reports Generated ===
            dir "%WORKSPACE%\\${reportDir}"
            dir "%WORKSPACE%\\${htmlDir}"
        """
    }

    // Archive & publish
    archiveArtifacts artifacts: "${reportDir}/**", fingerprint: true
    archiveArtifacts artifacts: "${htmlDir}/**", fingerprint: true

    publishHTML(target: [
        allowMissing: false,
        alwaysLinkToLastBuild: true,
        keepAll: true,
        reportDir: htmlDir,
        reportFiles: '*.html',
        reportName: 'Salesforce Code Analyzer v5 Report',
        reportTitles: 'Static Code Analysis HTML'
    ])
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
