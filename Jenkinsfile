// ==============================
// Utility Functions
// ==============================
def preCheckCredentials() {
    if (isUnix()) {
        sh """
            echo "=== Pre-Check: Validating Salesforce Credentials ==="
            if [ -z "$CONNECTED_APP_CONSUMER_KEY" ]; then
                echo "Missing CONNECTED_APP_CONSUMER_KEY"; exit 1
            fi
            if [ -z "$SFDC_USERNAME" ]; then
                echo "Missing SFDC_USERNAME"; exit 1
            fi
            if [ ! -f "$JWT_KEY_FILE" ]; then
                echo "Missing or invalid JWT_KEY_FILE: $JWT_KEY_FILE"; exit 1
            fi
            echo "All credentials found!"
        """
    } else {
        bat """
            echo === Pre-Check: Validating Salesforce Credentials ===
            if "%CONNECTED_APP_CONSUMER_KEY%"=="" (
                echo Missing CONNECTED_APP_CONSUMER_KEY
                exit /b 1
            )
            if "%SFDC_USERNAME%"=="" (
                echo Missing SFDC_USERNAME
                exit /b 1
            )
            if not exist "%JWT_KEY_FILE%" (
                echo Missing or invalid JWT_KEY_FILE: %JWT_KEY_FILE%
                exit /b 1
            )
            echo All credentials found!
        """
    }
}

def authenticateOrg() {
    if (isUnix()) {
        sh """
            echo "Authenticating to Salesforce Org: $ORG_ALIAS..."
            echo Using client-id: $CONNECTED_APP_CONSUMER_KEY
            echo Using username: $SFDC_USERNAME
            echo Using key file: $JWT_KEY_FILE

            sf org login jwt \
                --client-id $CONNECTED_APP_CONSUMER_KEY \
                --jwt-key-file $JWT_KEY_FILE \
                --username $SFDC_USERNAME \
                --alias $ORG_ALIAS \
                --instance-url $SFDC_HOST
        """
    } else {
        bat """
            echo Authenticating to Salesforce Org: %ORG_ALIAS%
            echo Using client-id: %CONNECTED_APP_CONSUMER_KEY%
            echo Using username: %SFDC_USERNAME%
            echo Using key file: %JWT_KEY_FILE%

            sf org login jwt ^
                --client-id %CONNECTED_APP_CONSUMER_KEY% ^
                --jwt-key-file %JWT_KEY_FILE% ^
                --username %SFDC_USERNAME% ^
                --alias %ORG_ALIAS% ^
                --instance-url %SFDC_HOST%
        """
    }
}

// ==============================
// Fixed Deployment Functions
// ==============================
def validatePreDeployment() {
    if (isUnix()) {
        sh """
            sf project deploy validate \
                --target-org $ORG_ALIAS \
                --source-dir force-app \
                --wait 10
        """
    } else {
        bat """
            sf project deploy validate ^
                --target-org %ORG_ALIAS% ^
                --source-dir force-app ^
                --wait 10
        """
    }
}

def deployToOrg() {
    if (isUnix()) {
        sh """
            sf project deploy start \
                --target-org $ORG_ALIAS \
                --source-dir force-app \
                --wait 10
        """
    } else {
        bat """
            sf project deploy start ^
                --target-org %ORG_ALIAS% ^
                --source-dir force-app ^
                --wait 10
        """
    }
}

def apexTestExecution() {
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

                    archiveArtifacts artifacts: "${htmlDir}/**", fingerprint: true
                    def reportUrl = "${env.WORKSPACE}\\${htmlDir}\\${htmlReport}"
                    echo "View Report URL :: ${reportUrl}"
                }

                stage('Pre-Check Credentials') {
                    preCheckCredentials()
                }

                stage('Authenticate Org') {
                    authenticateOrg()
                }

                stage('Pre-Deployment Validation') {
                    validatePreDeployment()
                }

                stage('Deploy to Org') {
                    deployToOrg()
                }

                stage('Apex Test Execution') {
                    apexTestExecution()
                }

                stage('Post-Deployment Verification') {
                    echo "Deployment & tests completed successfully for $ORG_ALIAS!"
                }
            }
        }
    } catch (err) {
        echo "Pipeline failed: ${err}"
        currentBuild.result = 'FAILURE'
        throw err
    }
}
