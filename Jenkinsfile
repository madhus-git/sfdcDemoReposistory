// ------------------------
// Utility Functions
// ------------------------
def authenticateOrg(orgAlias, sfdcHost, consumerKey, jwtKeyFile, username) {
    if (isUnix()) {
        sh """
            echo "Authenticating to Salesforce Org: ${orgAlias}..."
            sf org login jwt --client-id ${consumerKey} \
                             --jwt-key-file ${jwtKeyFile} \
                             --username ${username} \
                             --alias ${orgAlias} \
                             --instance-url ${sfdcHost}
        """
    } else {
        bat """
            echo Authenticating to Salesforce Org: ${orgAlias}...
            sf org login jwt --client-id %CONNECTED_APP_CONSUMER_KEY% ^
                             --jwt-key-file %JWT_KEY_FILE% ^
                             --username %SFDC_USERNAME% ^
                             --alias ${orgAlias} ^
                             --instance-url ${sfdcHost}
        """
    }
}

def deployToOrg(orgAlias) {
    if (isUnix()) {
        sh "sf project deploy start --target-org ${orgAlias} --ignore-conflicts --wait 10"
    } else {
        bat "sf project deploy start --target-org ${orgAlias} --ignore-conflicts --wait 10"
    }
}

// ------------------------
// Pipeline
// ------------------------
node {

    // Enable GitHub webhook trigger
    properties([
        pipelineTriggers([
            pollSCM('H/1 * * * *')  // check repo every 1 min
        ])
    ])
    try {
        withCredentials([
            string(credentialsId: 'sfdc-consumer-key', variable: 'CONNECTED_APP_CONSUMER_KEY'),
            string(credentialsId: 'sfdc-username', variable: 'SFDC_USERNAME'),
            file(credentialsId: 'sfdc-jwt-key', variable: 'JWT_KEY_FILE')
        ]) {

            def SFDC_HOST = 'https://login.salesforce.com'
            def DEV_ORG_ALIAS = 'dev'
            def reportDir = 'pmd-report-html'
            def htmlReport = "${reportDir}/StaticAnalysisReport.html"
            def jsonReport = "${reportDir}/StaticAnalysisReport.json"
            def xmlReport = "${reportDir}/pmd-report.xml"

            stage('Clean Workspace') {
                cleanWs()
                echo "✅ Workspace cleaned successfully!"
            }

            stage('Checkout Source') {
                checkout scm
            }

            // ------------------------
            // Static Code Analysis
            // ------------------------
            stage('Static Code Analysis') {
            steps {
                sh '''
                    # Run Salesforce Code Analyzer twice:
                    # 1) Generate HTML report for human-readable view
                    # 2) Generate SARIF report for Jenkins Warnings NG integration
                    
                    mkdir -p pmd-report-html

                    sf scanner:run --target "force-app/main/default/classes" \
                                   --engine pmd \
                                   --format html \
                                   --outfile "pmd-report-html/StaticAnalysisReport.html" || exit 0

                    sf scanner:run --target "force-app/main/default/classes" \
                                   --engine pmd \
                                   --format sarif \
                                   --outfile "pmd-report-html/pmd-report.sarif.json" || exit 0
                '''
            }
        }
    }
    post {
        always {
            // Archive all reports
            archiveArtifacts artifacts: 'pmd-report-html/**', fingerprint: true

            // Publish HTML report (appears in left-hand menu)
            publishHTML([[
                allowMissing: false,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'pmd-report-html',
                reportFiles: 'StaticAnalysisReport.html',
                reportName: 'Salesforce Static Analysis Report'
            ]])

            // Publish SARIF report to Warnings NG (trend charts, drill down)
            recordIssues tools: [sarif(name: 'Salesforce Code Analyzer')],
                         pattern: 'pmd-report-html/pmd-report.sarif.json'
        }






            /*stage('Authenticate Dev Org') {
                authenticateOrg(DEV_ORG_ALIAS, SFDC_HOST, CONNECTED_APP_CONSUMER_KEY, JWT_KEY_FILE, SFDC_USERNAME)
            }

            stage('Deploy to Dev Org') {
                deployToOrg(DEV_ORG_ALIAS)
            }*/
        }

    } catch (err) {
        echo "❌ Pipeline failed: ${err}"
        currentBuild.result = 'FAILURE'
        throw err
    } finally {
        echo "Pipeline completed."
    }
}
