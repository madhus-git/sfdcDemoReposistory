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

                // Clean-up Workspace
                stage('Clean Workspace') {
                    cleanWs()
                }

                // Checkout Source Code
                stage('Checkout Source') {
                    checkout scm
                }

                // Install Prerequisites
                stage('Install Prerequisites') {
                    if (isUnix()) {
                        sh '''
                            if ! command -v sf >/dev/null 2>&1; then
                                npm install --global @salesforce/cli
                            fi
                            sf plugins install @salesforce/sfdx-scanner || echo "Plugin already installed"
                            sf plugins update @salesforce/sfdx-scanner
                        '''
                    } else {
                        bat '''
                            where sf >nul 2>nul
                            if %ERRORLEVEL% neq 0 (
                                npm install --global @salesforce/cli
                            )
                            sf plugins install @salesforce/sfdx-scanner || echo Plugin already installed
                            sf plugins update @salesforce/sfdx-scanner
                        '''
                    }
                }

                // Static Code Analysis
                stage('Static Code Analysis') {
                    def htmlDir    = 'html-report'
                    def htmlReport = 'CodeAnalyzerReport.html'

                    if (isUnix()) {
                        sh """
                            rm -rf ${htmlDir}
                            mkdir -p ${htmlDir}
                            sf code-analyzer run --workspace force-app --rule-selector Recommended --output-file ${htmlDir}/${htmlReport}
                        """
                    } else {
                        bat """
                            if exist "${htmlDir}" rmdir /s /q "${htmlDir}"
                            mkdir "${htmlDir}"
                            sf code-analyzer run --workspace force-app --rule-selector Recommended --output-file "%WORKSPACE%\\${htmlDir}\\${htmlReport}"
                        """
                    }

                    // Archive report artifacts
                    archiveArtifacts artifacts: "${htmlDir}/**", fingerprint: true

                    // Build URL for direct access
                    def reportUrl = "${env.BUILD_URL}artifact/${htmlDir}/${htmlReport}"
                    def viewReportUrl = "${env.WORKSPACE}\\${htmlDir}\\${htmlReport}"
                    echo "View Report URL :: ${viewReportUrl}"

                    // Log to console
                    echo "Open the Salesforce Code Analyzer Report here: ${viewReportUrl}"
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