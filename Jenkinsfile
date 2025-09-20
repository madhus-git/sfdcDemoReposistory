// ==============================
// Utility Functions
// ==============================
def preCheckCredentials() {
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
            echo "✅ Pre-check passed: All Salesforce credentials are available"
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
            echo ✅ Pre-check passed: All Salesforce credentials are available
        """
    }
}

def authenticateOrg() {
    if (isUnix()) {
        sh """
            echo "Authenticating to Salesforce Org: $ORG_ALIAS..."
            sf org login jwt \
                --client-id $CONNECTED_APP_CONSUMER_KEY \
                --jwt-key-file $JWT_KEY_FILE \
                --username $SFDC_USERNAME \
                --alias $ORG_ALIAS \
                --instance-url $SFDC_HOST
            echo "✅ Authentication completed for Org: $ORG_ALIAS"
        """
    } else {
        bat """
            echo Authenticating to Salesforce Org: %ORG_ALIAS%...
            sf org login jwt ^
                --client-id %CONNECTED_APP_CONSUMER_KEY% ^
                --jwt-key-file %JWT_KEY_FILE% ^
                --username %SFDC_USERNAME% ^
                --alias %ORG_ALIAS% ^
                --instance-url %SFDC_HOST%
            echo ✅ Authentication completed for Org: %ORG_ALIAS%
        """
    }
}

def validatePreDeployment() {
    if (isUnix()) {
        sh """
            echo "Validating deployment to Org: $ORG_ALIAS..."
            sf project deploy validate --target-org $ORG_ALIAS --source-dir force-app --wait 10
        """
    } else {
        bat """
            echo Validating deployment to Org: %ORG_ALIAS%...
            sf project deploy validate --target-org %ORG_ALIAS% --source-dir force-app --wait 10
        """
    }
}

def deployToOrg() {
    if (isUnix()) {
        sh """
            echo "Deploying to Org: $ORG_ALIAS..."
            sf project deploy start --target-org $ORG_ALIAS --source-dir force-app --wait 10
        """
    } else {
        bat """
            echo Deploying to Org: %ORG_ALIAS%...
            sf project deploy start --target-org %ORG_ALIAS% --source-dir force-app --wait 10
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
        echo "✅ Apex tests completed successfully for Org: $ORG_ALIAS"
    } catch (Exception e) {
        error "[ERROR] Apex Unit Tests failed. Please check test results in Jenkins."
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

                stage('Clean Workspace') {
                    cleanWs()
                    echo "✅ Workspace cleaned successfully!"
                }

                stage('Checkout Source') { checkout scm }

                stage('Install Prerequisites') {
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
                }

                stage('Static Code Analysis') {
                    def htmlDir    = 'html-report'
                    def htmlReport = 'CodeAnalyzerReport.html'

                    if (isUnix()) {
                        sh """
                            rm -rf ${htmlDir}
                            mkdir -p ${htmlDir}
                            sf code-analyzer run --workspace force-app --rule-selector Recommended --output-file ${htmlDir}/${htmlReport} || echo ⚠️ Code Analyzer found issues, check report.
                        """
                    } else {
                        bat """
                            if exist "${htmlDir}" rmdir /s /q "${htmlDir}"
                            mkdir "${htmlDir}"
                            sf code-analyzer run --workspace force-app --rule-selector Recommended --output-file "%WORKSPACE%\\${htmlDir}\\${htmlReport}" || echo ⚠️ Code Analyzer found issues, check report.
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

                stage('Upload Static Code Analysis Report to Nexus') {
                    script {
                        def projectName = "SF-CICD-POC"
                        def branchName  = env.BRANCH_NAME ?: env.GIT_BRANCH ?: "unknown"
                        branchName = branchName.replaceAll(/^refs\/heads\//, "").replaceAll(/[^\w\-.]/, "_")
                        def nexusPath   = "${projectName}/${branchName}/${env.BUILD_NUMBER}"

                        try {
                            withCredentials([usernamePassword(credentialsId: 'nexus-credentials', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                                if (isUnix()) {
                                    sh """
                                        curl -s -u \$NEXUS_USER:\$NEXUS_PASS \
                                             --upload-file html-report/CodeAnalyzerReport.html \
                                             \$NEXUS_URL/${nexusPath}/CodeAnalyzerReport.html
                                    """
                                } else {
                                    bat """
                                        curl -s -u %NEXUS_USER%:%NEXUS_PASS% ^
                                             --upload-file html-report\\CodeAnalyzerReport.html ^
                                             %NEXUS_URL%/${nexusPath}/CodeAnalyzerReport.html
                                    """
                                }
                            }
                            echo "✅ Report uploaded to Nexus: $NEXUS_URL/${nexusPath}/CodeAnalyzerReport.html"
                        } catch (Exception e) {
                            error "[ERROR] Failed to upload report to Nexus: ${e}"
                        }
                    }
                }

                stage('Pre-Check Credentials') { preCheckCredentials() }
                stage('Authenticate Org') { authenticateOrg() }
                stage('Pre-Deployment Validation') { validatePreDeployment() }
                stage('Deploy to Org') { deployToOrg() }
                stage('Apex Test Execution') { apexTestExecution() }

                stage('Post-Deployment Verification') {
                    echo "✅ Deployment & tests completed successfully for $ORG_ALIAS!"
                }
            }
        }
    } catch (err) {
        echo "[ERROR] Pipeline failed: ${err}"
        currentBuild.result = 'FAILURE'
        throw err
    }
}
