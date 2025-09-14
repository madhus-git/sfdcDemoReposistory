// ==============================
// Utility Functions
// ==============================
def authenticateOrg() {
    if (isUnix()) {
        sh """
            echo "Authenticating to Salesforce Org: $ORG_ALIAS..."
            sf org login jwt --client-id "$CONNECTED_APP_CONSUMER_KEY" \\
                             --jwt-key-file "$JWT_KEY_FILE" \\
                             --username "$SFDC_USERNAME" \\
                             --alias "$ORG_ALIAS" \\
                             --instance-url "$SFDC_HOST"
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

            // Workspace-relative path for artifacts
            def reportDir   = 'pmd-report-html'
            def htmlReport  = reportDir + (isUnix() ? "/StaticAnalysisReport.html" : "\\StaticAnalysisReport.html")
            def sarifReport = reportDir + (isUnix() ? "/pmd-report.sarif" : "\\pmd-report.sarif")

            withEnv([
                "SFDC_HOST=https://login.salesforce.com",
                "ORG_ALIAS=projectdemosfdc"
            ]) {

                // --------------------------
                // Clean Workspace
                // --------------------------
                stage('Clean Workspace') {
                    cleanWs()
                    echo "Workspace cleaned successfully!"
                }

                // --------------------------
                // Checkout Source
                // --------------------------
                stage('Checkout Source') {
                    checkout scm
                }

                // --------------------------
                // Install Salesforce CLI
                // --------------------------
                stage('Install prerequisite') {
                    if (isUnix()) {
                        sh '''
                            if ! command -v sf >/dev/null 2>&1; then
                                echo "Salesforce CLI not found, installing..."
                                npm install --global @salesforce/cli
                            else
                                echo "Salesforce CLI is already installed."
                                sf --version
                            fi
                        '''
                    } else {
                        bat '''
                            where sf >nul 2>nul
                            if %ERRORLEVEL% neq 0 (
                                echo Salesforce CLI not found, installing...
                                npm install --global @salesforce/cli
                            ) else (
                                echo Salesforce CLI is already installed.
                                sf --version
                            )
                        '''
                    }
                }

                // --------------------------
                // Static Code Analysis
                // --------------------------
                stage('Static Code Analysis') {
                    if (isUnix()) {
                        sh """
                            mkdir -p ${reportDir}

                            sf scanner:run --target "force-app/main/default/classes" \\
                                           --engine pmd \\
                                           --format html \\
                                           --outfile "${htmlReport}" || true

                            sf scanner:run --target "force-app/main/default/classes" \\
                                           --engine pmd \\
                                           --format sarif \\
                                           --outfile "${sarifReport}" || true
                        """
                    } else {
                        bat """
                            if not exist "${reportDir}" mkdir "${reportDir}"

                            sf scanner:run --target "force-app/main/default/classes" ^
                                           --engine pmd ^
                                           --format html ^
                                           --outfile "%WORKSPACE%\\${htmlReport}" || exit 0

                            sf scanner:run --target "force-app/main/default/classes" ^
                                           --engine pmd ^
                                           --format sarif ^
                                           --outfile "%WORKSPACE%\\${sarifReport}" || exit 0
                        """
                    }
                }

                // --------------------------
                // Verify Reports
                // --------------------------
                stage('Verify Reports') {
                    if (isUnix()) {
                        sh "ls -l ${reportDir}"
                    } else {
                        bat "dir ${reportDir}"
                    }
                }

                // --------------------------
                // Publish Reports (HTML + SARIF)
                // --------------------------
                stage('Publish Reports') {
                    // Archive all reports
                    archiveArtifacts artifacts: "${reportDir}/**", fingerprint: true

                    // Publish HTML report (clickable in Jenkins sidebar)
                    publishHTML(target: [
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: reportDir,
                        reportFiles: 'StaticAnalysisReport.html',
                        reportName: 'Salesforce PMD Dashboard',
                        reportTitles: 'Salesforce Static Analysis',
                        escapeUnderscores: false
                    ])

                    // Publish SARIF to Warnings NG (trend graphs)
                    recordIssues(
                        tools: [sarif(
                            name: 'Salesforce Code Analyzer',
                            pattern: "${sarifReport}"
                        )],
                        qualityGates: [
                            [threshold: 1, type: 'TOTAL_ERROR', unstable: false],
                            [threshold: 1, type: 'TOTAL_HIGH',  unstable: false],
                            [threshold: 5, type: 'TOTAL_NORMAL', unstable: true]
                        ]
                    )

                    // Echo clickable links in console
                    echo "👉 Salesforce PMD Dashboard: ${env.BUILD_URL}Salesforce_20PMD_20Dashboard/"
                    echo "👉 SARIF Warnings NG Trends: ${env.BUILD_URL}analysis/"
                }

                // --------------------------
                // Authenticate Dev Org
                // --------------------------
                stage('Authenticate Org') {
                    authenticateOrg()
                }

                // --------------------------
                // Deploy to Dev Org
                // --------------------------
                stage('Deploy to Org') {
                    deployToOrg()
                }
            }
        }
    } catch (err) {
        echo "Pipeline failed: ${err}"
        currentBuild.result = 'FAILURE'
        throw err
    }
}
