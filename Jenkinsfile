// ==============================
// Utility Functions
// ==============================

// Color-coded console messages
def colorEcho(message, type='INFO') {
    if (type == 'SUCCESS') {
        echo "\u001B[32m[SUCCESS] ${message}\u001B[0m" // Green
    } else if (type == 'ERROR') {
        echo "\u001B[31m[ERROR] ${message}\u001B[0m"   // Red
    } else {
        echo message
    }
}

// Pre-check Salesforce Credentials
def preCheckCredentials() {
    colorEcho("Pre-check SF Credentials")
    if (isUnix()) {
        sh """
            if [ -z "$CONNECTED_APP_CONSUMER_KEY" ]; then
                echo "[ERROR] Missing CONNECTED_APP_CONSUMER_KEY"; exit 1
            fi
            if [ -z "$SFDC_USERNAME" ]; then
                echo "[ERROR] Missing SFDC_USERNAME"; exit 1
            fi
            if [ ! -f "$JWT_KEY_FILE" ]; then
                echo "[ERROR] Missing or invalid JWT_KEY_FILE: $JWT_KEY_FILE"; exit 1
            fi
            echo "Pre-check passed: All Salesforce credentials are available"
        """
    } else {
        bat """
            if "%CONNECTED_APP_CONSUMER_KEY%"=="" (
                echo [ERROR] Missing CONNECTED_APP_CONSUMER_KEY
                exit /b 1
            )
            if "%SFDC_USERNAME%"=="" (
                echo [ERROR] Missing SFDC_USERNAME
                exit /b 1
            )
            if not exist "%JWT_KEY_FILE%" (
                echo [ERROR] Missing or invalid JWT_KEY_FILE: %JWT_KEY_FILE%
                exit /b 1
            )
            echo Pre-check passed: All Salesforce credentials are available
        """
    }
    colorEcho("Salesforce credentials pre-check completed", "SUCCESS")
}

// Authenticate Salesforce Org
def authenticateOrg() {
    colorEcho("Authenticating to Salesforce Org :: $ORG_ALIAS")
    if (isUnix()) {
        sh """
            sf org login jwt \
                --client-id $CONNECTED_APP_CONSUMER_KEY \
                --jwt-key-file $JWT_KEY_FILE \
                --username $SFDC_USERNAME \
                --alias $ORG_ALIAS \
                --instance-url $SFDC_HOST
        """
    } else {
        bat """
            sf org login jwt ^ 
                --client-id %CONNECTED_APP_CONSUMER_KEY% ^
                --jwt-key-file %JWT_KEY_FILE% ^
                --username %SFDC_USERNAME% ^
                --alias %ORG_ALIAS% ^
                --instance-url %SFDC_HOST%
        """
    }
    colorEcho("Authenticated successfully with Org: $ORG_ALIAS", "SUCCESS")
}

// Pre-deployment validation
def validatePreDeployment() {
    colorEcho("Validating pre-deployment to Org :: $ORG_ALIAS")
    if (isUnix()) {
        sh "sf project deploy validate --target-org $ORG_ALIAS --source-dir force-app --wait 10"
    } else {
        bat "sf project deploy validate --target-org %ORG_ALIAS% --source-dir force-app --wait 10"
    }
    colorEcho("Pre-deployment validation passed for Org: $ORG_ALIAS", "SUCCESS")
}

// Deploy to Org
def deployToOrg() {
    colorEcho("Deploying to Org :: $ORG_ALIAS")
    if (isUnix()) {
        sh "sf project deploy start --target-org $ORG_ALIAS --source-dir force-app --wait 10"
    } else {
        bat "sf project deploy start --target-org %ORG_ALIAS% --source-dir force-app --wait 10"
    }
}

// Display file-wise deployment report
def displayDeploymentReport() {
    colorEcho("Fetching Salesforce Deployment Report for Org: $ORG_ALIAS")
    if (isUnix()) {
        sh """
            echo State      Name                  Type         Path
            echo -----------------------------------------------------------
            sf project deploy report --target-org $ORG_ALIAS
        """
    } else {
        bat """
            echo State      Name                  Type         Path
            echo -----------------------------------------------------------
            sf project deploy report --target-org %ORG_ALIAS%
        """
    }
}

// Apex Unit Tests Execution
def apexTestExecution() {
    try {
        colorEcho("Running Apex Unit Tests in Org :: $ORG_ALIAS")
        if (isUnix()) {
            sh "sf apex run test --target-org $ORG_ALIAS --result-format junit --output-dir test-results --wait 10"
        } else {
            bat "sf apex run test --target-org %ORG_ALIAS% --result-format junit --output-dir test-results --wait 10"
        }
        junit allowEmptyResults: false, testResults: 'test-results/**/*.xml'
        colorEcho("Apex tests completed successfully for Org: $ORG_ALIAS", "SUCCESS")
    } catch (Exception e) {
        colorEcho("Apex Unit Tests failed. Please check test results in Jenkins.", "ERROR")
        error "[ERROR] Apex Unit Tests failed. See Jenkins logs."
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
            file(credentialsId: 'sfdc-jwt-key', variable: 'JWT_KEY_FILE'),
            usernamePassword(credentialsId: 'nexus-credentials', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')
        ]) {

            withEnv([
                "SFDC_HOST=https://login.salesforce.com",
                "ORG_ALIAS=projectdemosfdc",
                "NEXUS_URL=http://localhost:8081/repository/StaticCodeAnalysisReports"
            ]) {

                stage('Checkout Source') { 
                    colorEcho("Checkout Source code")
                    checkout scm 
                }

                stage('Install Prerequisites') {
                    colorEcho("Installing prerequisites for CICD")
                    if (isUnix()) {
                        sh '''
                            if ! command -v sf >/dev/null 2>&1; then
                                npm install --global @salesforce/cli@2.61.8
                            fi
                            sf plugins install @salesforce/sfdx-scanner@3.16.0 || echo "Plugin already installed"
                            sf plugins update @salesforce/sfdx-scanner
                        '''
                    } else {
                        bat '''
                            where sf >nul 2>nul
                            if %ERRORLEVEL% neq 0 (
                                npm install --global @salesforce/cli@2.61.8
                            )
                            sf plugins install @salesforce/sfdx-scanner@3.16.0 || echo Plugin already installed
                            sf plugins update @salesforce/sfdx-scanner
                        '''
                    }
                    colorEcho("Prerequisites installation completed", "SUCCESS")
                }

                stage('Static Code Analysis') {
                    colorEcho("Performing SCA for Salesforce Code")
                    def htmlDir = 'html-report'
                    def dateStamp = new Date().format("ddMMyy")
                    def buildNumber = env.BUILD_NUMBER
                    def htmlReport = "CodeAnalyzerReport_${dateStamp}_${buildNumber}.html"

                    if (isUnix()) {
                        sh """
                            rm -rf ${htmlDir}
                            mkdir -p ${htmlDir}
                            sf code-analyzer run --workspace force-app --rule-selector Recommended --output-file ${htmlDir}/${htmlReport} || echo ⚠️ Code Analyzer found issues
                        """
                    } else {
                        bat """
                            if exist "${htmlDir}" rmdir /s /q "${htmlDir}"
                            mkdir "${htmlDir}"
                            sf code-analyzer run --workspace force-app --rule-selector Recommended --output-file "%WORKSPACE%\\${htmlDir}\\${htmlReport}" || echo ⚠️ Code Analyzer found issues
                        """
                    }

                    archiveArtifacts artifacts: "${htmlDir}/**", fingerprint: true

                    publishHTML([
                        reportDir: "${htmlDir}",
                        reportFiles: htmlReport,
                        reportName: "Salesforce Code Analyzer Report",
                        keepAll: true,
                        alwaysLinkToLastBuild: true,
                        allowMissing: false
                    ])
                    colorEcho("Static Code Analysis completed", "SUCCESS")
                }

                stage('Upload SCA Report') {
                    colorEcho("Uploading SCA Report to Nexus")
                    script {
                        def projectName = "SF-CICD-POC"
                        def branchName  = env.BRANCH_NAME ?: env.GIT_BRANCH ?: "unknown"
                        branchName = branchName.replaceAll(/^refs\/heads\//, "").replaceAll(/[^\w\-.]/, "_")
                        def dateStamp = new Date().format("ddMMyy")
                        def buildNumber = env.BUILD_NUMBER
                        def htmlReport = "CodeAnalyzerReport_${dateStamp}_${buildNumber}.html"
                        def nexusPath = "${projectName}/${branchName}/${buildNumber}"

                        try {
                            if (isUnix()) {
                                sh """
                                    HTTP_CODE=\$(curl -s -o /dev/null -w '%{http_code}' -u \$NEXUS_USER:\$NEXUS_PASS \
                                        --upload-file html-report/${htmlReport} \
                                        \$NEXUS_URL/${nexusPath}/${htmlReport})
                                    if [ "\$HTTP_CODE" != "201" ]; then
                                        echo "[ERROR] Nexus upload failed with HTTP code: \$HTTP_CODE"
                                        exit 1
                                    fi
                                """
                            } else {
                                bat """
                                    for /f %%i in ('curl -s -o nul -w "%%{http_code}" -u %NEXUS_USER%:%NEXUS_PASS% ^
                                        --upload-file html-report\\${htmlReport} ^
                                        %NEXUS_URL%/${nexusPath}/${htmlReport}') do set HTTP_CODE=%%i
                                    if not "%HTTP_CODE%"=="201" (
                                        echo [ERROR] Nexus upload failed with HTTP code: %HTTP_CODE%
                                        exit /b 1
                                    )
                                """
                            }
                            colorEcho("Report uploaded to Nexus: $NEXUS_URL/${nexusPath}/${htmlReport}", "SUCCESS")
                        } catch (Exception e) {
                            colorEcho("Failed to upload report to Nexus: ${e}", "ERROR")
                            error "[ERROR] Nexus upload failed."
                        }
                    }
                }

                stage('Pre-Check Credentials') { preCheckCredentials() }
                stage('Authenticate Org') { authenticateOrg() }
                stage('Pre-Deployment Validation') { validatePreDeployment() }

                stage('Deploy to Org') {
                    displayDeploymentReport()
                    try {
                        deployToOrg()
                        colorEcho("Deployment completed successfully for Org: $ORG_ALIAS", "SUCCESS")
                    } catch (Exception e) {
                        colorEcho("Deployment failed for Org: $ORG_ALIAS. Check logs.", "ERROR")
                        throw e
                    }
                }

                stage('Apex Test Execution') { apexTestExecution() }
                stage('Post-Deployment Verification') { colorEcho("Deployment & tests completed successfully for $ORG_ALIAS!", "SUCCESS") }

                stage('Clean Workspace') {
                    cleanWs()
                    colorEcho("Workspace cleaned successfully!", "SUCCESS")
                }

            }
        }
    } catch (err) {
        colorEcho("Pipeline failed: ${err}", "ERROR")
        currentBuild.result = 'FAILURE'
        throw err
    }
}
