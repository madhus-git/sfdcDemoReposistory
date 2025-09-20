// Jenkinsfile — no suppressed commands

// ==============================
// Utility Functions
// ==============================
def preCheckCredentials() {
    echo "Pre-check SF Credentials"
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
            @echo off
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
}

def authenticateOrg() {
    echo "Authenticating to Salesforce Org :: $ORG_ALIAS"
    if (isUnix()) {
        sh """
            set -o pipefail
            sf org login jwt \
                --client-id "$CONNECTED_APP_CONSUMER_KEY" \
                --jwt-key-file "$JWT_KEY_FILE" \
                --username "$SFDC_USERNAME" \
                --alias "$ORG_ALIAS" \
                --instance-url "$SFDC_HOST"
        """
    } else {
        bat """
            @echo off
            sf org login jwt ^
                --client-id "%CONNECTED_APP_CONSUMER_KEY%" ^
                --jwt-key-file "%JWT_KEY_FILE%" ^
                --username "%SFDC_USERNAME%" ^
                --alias "%ORG_ALIAS%" ^
                --instance-url "%SFDC_HOST%"
        """
    }
}

def validatePreDeployment() {
    echo "Validating pre-deployment to Org :: $ORG_ALIAS"
    if (isUnix()) {
        sh "sf project deploy validate --target-org $ORG_ALIAS --source-dir force-app --wait 10"
    } else {
        bat """
            @echo off
            sf project deploy validate --target-org %ORG_ALIAS% --source-dir force-app --wait 10
        """
    }
}

def deployToOrg() {
    echo "Deploying to Org :: $ORG_ALIAS"
    if (isUnix()) {
        sh "sf project deploy start --target-org $ORG_ALIAS --source-dir force-app --wait 10"
    } else {
        bat """
            @echo off
            sf project deploy start --target-org %ORG_ALIAS% --source-dir force-app --wait 10
        """
    }
}

def apexTestExecution() {
    try {
        echo "Running Apex Unit Tests in Org :: $ORG_ALIAS"
        if (isUnix()) {
            sh "sf apex run test --target-org $ORG_ALIAS --result-format junit --output-dir test-results --wait 10"
        } else {
            bat """
                @echo off
                sf apex run test --target-org %ORG_ALIAS% --result-format junit --output-dir test-results --wait 10
            """
        }
        junit allowEmptyResults: false, testResults: 'test-results/**/*.xml'
        echo "Apex tests completed successfully for Org: $ORG_ALIAS"
    } catch (Exception e) {
        error "[ERROR] Apex Unit Tests failed. Please check test results in Jenkins. ${e}"
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
                    echo "Checkout Source code"
                    checkout scm 
                }

                stage('Install Prerequisites') {
                    echo "Install Prerequisites for CICD"
                    if (isUnix()) {
                        sh '''
                            # fail-fast behavior: don't swallow errors
                            if ! command -v sf >/dev/null 2>&1; then
                                npm install --global @salesforce/cli@2.61.8
                            fi
                            sf plugins install @salesforce/sfdx-scanner@3.16.0
                            sf plugins update @salesforce/sfdx-scanner
                        '''
                    } else {
                        bat """
                            @echo off
                            where sf >nul 2>nul
                            if %ERRORLEVEL% neq 0 (
                                npm install --global @salesforce/cli@2.61.8
                            )
                            sf plugins install @salesforce/sfdx-scanner@3.16.0
                            sf plugins update @salesforce/sfdx-scanner
                        """
                    }
                }

                stage('Static Code Analysis') {
                    echo "Performing SCA for SF Code"
                    def htmlDir = 'html-report'
                    def dateStamp = new Date().format("ddMMyy")
                    def buildNumber = env.BUILD_NUMBER
                    def htmlReport = "CodeAnalyzerReport_${dateStamp}_${buildNumber}.html"

                    if (isUnix()) {
                        sh """
                            rm -rf ${htmlDir}
                            mkdir -p ${htmlDir}
                            # do not suppress failures — let pipeline mark failed when analyzer returns non-zero
                            sf code-analyzer run --workspace force-app --rule-selector Recommended --output-file ${htmlDir}/${htmlReport}
                        """
                    } else {
                        bat """
                            @echo off
                            if exist "${htmlDir}" rmdir /s /q "${htmlDir}"
                            mkdir "${htmlDir}"
                            sf code-analyzer run --workspace force-app --rule-selector Recommended --output-file "%WORKSPACE%\\${htmlDir}\\${htmlReport}"
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
                }

                stage('Upload SCA Report') {
                    echo "Uploading SCA Report to Nexus"
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
                                    HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' -u $NEXUS_USER:$NEXUS_PASS \
                                        --upload-file html-report/${htmlReport} \
                                        $NEXUS_URL/${nexusPath}/${htmlReport})
                                    if [ "$HTTP_CODE" != "201" ]; then
                                        echo "[ERROR] Nexus upload failed with HTTP code: $HTTP_CODE"
                                        exit 1
                                    fi
                                """
                            } else {
                                bat """
                                    @echo off
                                    for /f %%i in ('curl -s -o nul -w "%%{http_code}" -u %NEXUS_USER%:%NEXUS_PASS% ^
                                        --upload-file html-report\\${htmlReport} ^
                                        %NEXUS_URL%/${nexusPath}/${htmlReport}') do set HTTP_CODE=%%i
                                    if not "%HTTP_CODE%"=="201" (
                                        echo [ERROR] Nexus upload failed with HTTP code: %HTTP_CODE%
                                        exit /b 1
                                    )
                                """
                            }
                            echo "Report uploaded to Nexus: $NEXUS_URL/${nexusPath}/${htmlReport}"
                        } catch (Exception e) {
                            error "[ERROR] Failed to upload report to Nexus: ${e}"
                        }
                    }
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
                
                stage('Clean Workspace') { 
                    cleanWs()
                    echo "Workspace cleaned successfully!" 
                }
            }
        }
    } catch (err) {
        echo "[ERROR] Pipeline failed: ${err}"
        currentBuild.result = 'FAILURE'
        throw err
    }
}
