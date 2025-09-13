// ==============================
// Utility Functions
// ==============================
def authenticateOrg() {
    if (isUnix()) {
        sh '''
            echo "Authenticating to Salesforce Org: $ORG_ALIAS..."
            sf org login jwt --client-id "$CONNECTED_APP_CONSUMER_KEY" \
                             --jwt-key-file "$JWT_KEY_FILE" \
                             --username "$SFDC_USERNAME" \
                             --alias "$ORG_ALIAS" \
                             --instance-url "$SFDC_HOST"
        '''
    } else {
        bat '''
            echo Authenticating to Salesforce Org: %ORG_ALIAS%...
            sf org login jwt --client-id %CONNECTED_APP_CONSUMER_KEY% ^ 
                             --jwt-key-file %JWT_KEY_FILE% ^ 
                             --username %SFDC_USERNAME% ^ 
                             --alias %ORG_ALIAS% ^ 
                             --instance-url %SFDC_HOST%
        '''
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
            def reportDir   = 'pmd-report-html'
            def htmlReport  = "${reportDir}/StaticAnalysisReport.html"
            def sarifReport = "${reportDir}/pmd-report.sarif"

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

                stage('Install Salesforce CLI') {
                    steps {
                        script {
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
                    }
                }

                stage('Static Code Analysis') {
                    steps {
                        script {
                            if (isUnix()) {
                                sh """
                                    mkdir -p ${reportDir}

                                    sf scanner:run --target "force-app/main/default/classes" \
                                                   --engine pmd \
                                                   --format html \
                                                   --outfile "${htmlReport}" || true

                                    sf scanner:run --target "force-app/main/default/classes" \
                                                   --engine pmd \
                                                   --format sarif \
                                                   --outfile "${sarifReport}" || true
                                """
                            } else {
                                bat """
                                    if not exist ${reportDir} mkdir ${reportDir}

                                    sf scanner:run --target "force-app/main/default/classes" ^ 
                                                   --engine pmd ^ 
                                                   --format html ^ 
                                                   --outfile "${htmlReport}" || exit 0

                                    sf scanner:run --target "force-app/main/default/classes" ^ 
                                                   --engine pmd ^ 
                                                   --format sarif ^ 
                                                   --outfile "${sarifReport}" || exit 0
                                """
                            }
                        }
                    }
                }

                stage('Copy Local Report (Optional)') {
                    steps {
                        script {
                            if (!fileExists(htmlReport)) {
                                if (isUnix()) {
                                    sh """
                                        mkdir -p ${reportDir}
                                        cp /path/to/local/StaticAnalysisReport.html ${htmlReport}
                                    """
                                } else {
                                    bat """
                                        if not exist ${reportDir} mkdir ${reportDir}
                                        copy "C:\\path\\to\\local\\StaticAnalysisReport.html" ${htmlReport}
                                    """
                                }
                            }
                        }
                    }
                }

                stage('Publish Reports') {
                    steps {
                        script {
                            archiveArtifacts artifacts: "${reportDir}/**", fingerprint: true

                            publishHTML(target: [
                                allowMissing: false,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: reportDir,
                                reportFiles: 'StaticAnalysisReport.html',
                                reportName: 'Salesforce Static Analysis Report'
                            ])

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
                        }
                    }
                }

                stage('Authenticate Dev Org') {
                    steps {
                        script {
                            authenticateOrg()
                        }
                    }
                }

                stage('Deploy to Dev Org') {
                    steps {
                        script {
                            deployToOrg()
                        }
                    }
                }
            }
        }
    } catch (err) {
        echo "Pipeline failed: ${err}"
        currentBuild.result = 'FAILURE'
        throw err
    } finally {
        echo "Pipeline completed."
    }
}
