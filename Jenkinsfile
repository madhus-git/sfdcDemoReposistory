// ==============================
// Utility Functions
// ==============================

def preCheckCredentials() {
    echo "Pre-check SF Credentials"
    if (isUnix()) {
        sh """
            set -x
            if [ -z "$CONNECTED_APP_CONSUMER_KEY" ]; then
                echo "[ERROR] Missing CONNECTED_APP_CONSUMER_KEY"; exit 1
            fi
            if [ -z "$SFDC_USERNAME" ]; then
                echo "[ERROR] Missing SFDC_USERNAME"; exit 1
            fi
            if [ ! -f "$JWT_KEY_FILE" ]; then
                echo "[ERROR] Missing or invalid JWT_KEY_FILE: $JWT_KEY_FILE"; exit 1
            fi
            echo "✅ Pre-check passed: All Salesforce credentials are available"
        """
    } else {
        bat """
            @echo off
            echo on
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
            echo ✅ Pre-check passed: All Salesforce credentials are available
        """
    }
}

def authenticateOrg() {
    echo "Authenticating to Salesforce Org :: ${ORG_ALIAS}"
    if (isUnix()) {
        sh """
            set -x
            sf org login jwt \
                --client-id $CONNECTED_APP_CONSUMER_KEY \
                --jwt-key-file $JWT_KEY_FILE \
                --username $SFDC_USERNAME \
                --alias $ORG_ALIAS \
                --instance-url $SFDC_HOST | tee auth.log
        """
    } else {
        bat """
            @echo off
            echo on
            sf org login jwt ^
                --client-id %CONNECTED_APP_CONSUMER_KEY% ^
                --jwt-key-file %JWT_KEY_FILE% ^
                --username %SFDC_USERNAME% ^
                --alias %ORG_ALIAS% ^
                --instance-url %SFDC_HOST%
        """
    }
}

def validatePreDeployment() {
    echo "Validating pre-deployment in Org :: ${ORG_ALIAS}"
    if (isUnix()) {
        sh """
            set -x
            sf project deploy validate --target-org $ORG_ALIAS --source-dir force-app --wait 10 | tee predeploy.log
        """
    } else {
        bat """
            @echo off
            echo on
            sf project deploy validate --target-org %ORG_ALIAS% --source-dir force-app --wait 10
        """
    }
}

def deployToOrg() {
    echo "Deploying to Org :: ${ORG_ALIAS}"
    if (isUnix()) {
        sh """
            set -x
            sf project deploy start --target-org $ORG_ALIAS --source-dir force-app --wait 10 | tee deploy.log
        """
    } else {
        bat """
            @echo off
            echo on
            sf project deploy start --target-org %ORG_ALIAS% --source-dir force-app --wait 10
        """
    }
}

def apexTestExecution() {
    echo "Running Apex Unit Tests in Org :: ${ORG_ALIAS}"
    try {
        if (isUnix()) {
            sh """
                set -x
                sf apex run test --target-org $ORG_ALIAS --result-format junit --output-dir test-results --wait 10 | tee test-results/apex.log
            """
        } else {
            bat """
                @echo off
                echo on
                sf apex run test --target-org %ORG_ALIAS% --result-format junit --output-dir test-results --wait 10
            """
        }
        junit allowEmptyResults: false, testResults: 'test-results/**/*.xml'
        echo "✅ Apex tests completed successfully for Org: ${ORG_ALIAS}"
    } catch (Exception e) {
        error "[ERROR] Apex Unit Tests failed. Check test-results in Jenkins."
    }
}

def runSCA() {
    echo "Running Static Code Analysis..."
    def htmlDir = 'html-report'
    def dateStamp = new Date().format("ddMMyy")
    def buildNumber = env.BUILD_NUMBER
    // ✅ Added .html extension
    def htmlReport = "CodeAnalyzerReport_${dateStamp}_${buildNumber}.html"

    if (isUnix()) {
        sh """
            set -x
            rm -rf ${htmlDir}
            mkdir -p ${htmlDir}
            sf code-analyzer run --workspace force-app --rule-selector Recommended --output-file ${htmlDir}/${htmlReport} | tee ${htmlDir}/sca.log
        """
    } else {
        bat """
            @echo off
            if exist "${htmlDir}" rmdir /s /q "${htmlDir}"
            mkdir "${htmlDir}"
            echo on
            sf code-analyzer run --workspace force-app --rule-selector Recommended --output-file "%WORKSPACE%\\\\${htmlDir}\\\\${htmlReport}"
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

def uploadToNexus() {
    echo "Uploading SCA Report to Nexus..."
    def projectName = "SF-CICD-POC"
    def branchName  = env.BRANCH_NAME ?: env.GIT_BRANCH ?: "unknown"
    branchName = branchName.replaceAll(/^refs\\/heads\\//, "").replaceAll(/[^\w\-.]/, "_")
    def dateStamp = new Date().format("ddMMyy")
    def buildNumber = env.BUILD_NUMBER
    // ✅ Using the same .html file name as SCA output
    def htmlReport = "CodeAnalyzerReport_${dateStamp}_${buildNumber}.html"
    def nexusPath = "${projectName}/${branchName}/${buildNumber}"

    if (isUnix()) {
        sh """
            set -x
            HTTP_CODE=\$(curl -s -o /dev/null -w '%{http_code}' -u \$NEXUS_USER:\$NEXUS_PASS \\
                --upload-file html-report/${htmlReport} \\
                \$NEXUS_URL/${nexusPath}/${htmlReport})
            if [ "\$HTTP_CODE" != "201" ]; then
                echo "[ERROR] Nexus upload failed with HTTP code: \$HTTP_CODE"
                exit 1
            fi
        """
    } else {
        bat """
            @echo off
            echo on
            for /f %%i in ('curl -s -o nul -w "%%{http_code}" -u %NEXUS_USER%:%NEXUS_PASS% ^
                --upload-file html-report\\\\${htmlReport} ^
                %NEXUS_URL%/${nexusPath}/${htmlReport}') do set HTTP_CODE=%%i
            if not "%HTTP_CODE%"=="201" (
                echo [ERROR] Nexus upload failed with HTTP code: %HTTP_CODE%
                exit /b 1
            )
        """
    }
    echo "Report uploaded to Nexus: ${NEXUS_URL}/${nexusPath}/${htmlReport}"
}

// ==============================
// Main Scripted Pipeline
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
                    echo "Checking out source code..."
                    checkout scm
                }

                stage('Install Prerequisites') {
                    echo "Installing Salesforce CLI and Scanner Plugin..."
                    if (isUnix()) {
                        sh """
                            set -x
                            if ! command -v sf >/dev/null 2>&1; then
                                npm install --global @salesforce/cli@2.61.8
                            fi
                            sf plugins install @salesforce/sfdx-scanner@3.16.0 || echo "Plugin already installed"
                            sf plugins update @salesforce/sfdx-scanner
                        """
                    } else {
                        bat """
                            @echo off
                            echo on
                            where sf >nul 2>nul
                            if %ERRORLEVEL% neq 0 (
                                npm install --global @salesforce/cli@2.61.8
                            )
                            sf plugins install @salesforce/sfdx-scanner@3.16.0 || echo Plugin already installed
                            sf plugins update @salesforce/sfdx-scanner
                        """
                    }
                }

                stage('Static Code Analysis') { runSCA() }
                stage('Upload SCA Report to Nexus') { uploadToNexus() }
                stage('Pre-Check Credentials') { preCheckCredentials() }
                stage('Authenticate Org')      { authenticateOrg() }
                stage('Pre-Deployment Validation') { validatePreDeployment() }
                stage('Deploy to Org')         { deployToOrg() }
                stage('Apex Test Execution')   { apexTestExecution() }

                stage('Clean Workspace') { 
                    echo "Cleaning workspace..."
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
