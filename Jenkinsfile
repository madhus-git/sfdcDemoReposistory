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

def validatePreDeployment(){
    if (isUnix()) {
        sh "sf project deploy validate --target-org $ORG_ALIAS --ignore-conflicts --wait 10"
    } else {
        bat "sf project deploy validate --target-org %ORG_ALIAS% --ignore-conflicts --wait 10"
    }
}

def apexTestExecution(){
    try {
        if (isUnix()) {
            sh """
                echo "Running Apex Unit Tests in Org: $ORG_ALIAS ..."
                sf apex run test --target-org $ORG_ALIAS --result-format junit --output-dir test-results --wait 10
            """
        } else {
            bat """
                echo Running Apex Unit Tests in Org: %ORG_ALIAS% ...
                sf apex run test --target-org %ORG_ALIAS% --result-format junit --output-dir test-results --wait 10
            """
        }

        // Archive test results
        junit allowEmptyResults: false, testResults: 'test-results/**/*.xml'

    } catch (Exception e) {
        error "Apex Unit Tests failed. Please check test results in Jenkins."
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
                    echo "Workspace cleaned successfully!"
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

                            echo "HTML Report Generated Successfully:"
                            ls -R ${htmlDir}
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

                            echo HTML Report Generated Successfully:
                            dir /s "%WORKSPACE%\\${htmlDir}"
                        """
                     }

                    // Archive report
                    archiveArtifacts artifacts: "${htmlDir}/**", fingerprint: true

                    // Build URL for direct access
                    def reportUrl = "${env.WORKSPACE}\\${htmlDir}\\${htmlReport}"
                    echo "View Report URL :: ${reportUrl}"

                    // Log to console
                    echo "Open the Salesforce Code Analyzer Report here: ${reportUrl}"

                    // Publish HTML
                    /*publishHTML(target: [
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: htmlDir,
                        reportFiles: htmlReport,
                        reportName: 'Salesforce Code Analyzer Report',
                        reportTitles: 'Static Code Analysis HTML'
                    ])

                    // Links
                    def artifactUrl = "${env.BUILD_URL}artifact/${htmlDir}/${htmlReport}"
                    def htmlTabUrl  = "${env.BUILD_URL}Salesforce_Code_Analyzer_Report/"

                    echo "Artifact Report (raw HTML): ${artifactUrl}"
                    echo "Published Dashboard (with Jenkins UI): ${htmlTabUrl}"*/

                    // Add both links in build description
                    /*currentBuild.description = """
                        <a href='${artifactUrl}' target='_blank'>📄 Artifact Report</a><br>
                        <a href='${htmlTabUrl}' target='_blank'>📊 Published Dashboard</a>
                    """*/
                }

                // Authenticate Org
                stage('Authenticate Org') {
                    authenticateOrg()
                }

                // Validate Pre-Deployment
                stage('Pre-Deployment Validation') {
                    validatePreDeployment()
                }

                // Deploy to Org
                stage('Deploy to Org') {
                    deployToOrg()
                }

                // Apex Unit Tests
                stage('Apex Test Execution') {
                    apexTestExecution()
                }

                // Post-Deployment Verification
                stage('Post-Deployment Verification') {
                    echo "Deployment & tests completed successfully for $ORG_ALIAS!"
                }

                // Notifications
                /*stage('Notifications') {
                    echo "Send notification to Slack/Email (integration needed)."
                }*/
            }
        }
    } catch (err) {
        echo "Pipeline failed: ${err}"
        currentBuild.result = 'FAILURE'
        throw err
    }
}