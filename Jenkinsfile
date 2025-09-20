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
    if (isUnix()) {
        sh "sf project deploy validate --target-org $ORG_ALIAS --source-dir force-app --wait 10"
    } else {
        bat "sf project deploy validate --target-org %ORG_ALIAS% --source-dir force-app --wait 10"
    }
}

def deployToOrg() {
    if (isUnix()) {
        sh "sf project deploy start --target-org $ORG_ALIAS --source-dir force-app --wait 10"
    } else {
        bat "sf project deploy start --target-org %ORG_ALIAS% --source-dir force-app --wait 10"
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
                            sf code-analyzer run --workspace force-app --rule-selector Recommended --output-file ${htmlDir}/${htmlReport} || echo "Code Analyzer found issues, check report."
                        """
                    } else {
                        bat """
                            if exist "${htmlDir}" rmdir /s /q "${htmlDir}"
                            mkdir "${htmlDir}"
                            sf code-analyzer run --workspace force-app --rule-selector Recommended --output-file "%WORKSPACE%\\${htmlDir}\\${htmlReport}" || echo Code Analyzer found issues, check report.
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
                        // Normalize branch name
                        def branchName = env.BRANCH_NAME ?: env.GIT_BRANCH ?: "unknown"
                        branchName = branchName.replaceAll(/^refs\/heads\//, "").replaceAll(/[^\w\-.]/, "_")

                        // Nexus storage path
                        def nexusPath = "${env.JOB_NAME}/${branchName}/${env.BUILD_NUMBER}"

                        echo "Uploading report to Nexus path: ${nexusPath}"

                        if (isUnix()) {
                            sh """
                                curl -v -u $NEXUS_USER:$NEXUS_PASS \
                                     --upload-file html-report/CodeAnalyzerReport.html \
                                     $NEXUS_URL/${nexusPath}/CodeAnalyzerReport.html
                            """
                        } else {
                            bat """
                                curl -v -u %NEXUS_USER%:%NEXUS_PASS% ^
                                     --upload-file html-report\\CodeAnalyzerReport.html ^
                                     %NEXUS_URL%/${nexusPath}/CodeAnalyzerReport.html
                            """
                        }

                        echo "Report available at: $NEXUS_URL/${nexusPath}/CodeAnalyzerReport.html"
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
            }
        }
    } catch (err) {
        echo "Pipeline failed: ${err}"
        currentBuild.result = 'FAILURE'
        throw err
    }
}
