// Utility Functions
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
            sf org login jwt --client-id %${consumerKey}% \
                             --jwt-key-file %${jwtKeyFile}% \
                             --username %${username}% \
                             --alias ${orgAlias} \
                             --instance-url %${sfdcHost}%
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

// Main Pipeline
node {
    try {
        withCredentials([
            string(credentialsId: 'sfdc-consumer-key', variable: 'CONNECTED_APP_CONSUMER_KEY'),
            string(credentialsId: 'sfdc-username', variable: 'SFDC_USERNAME'),
            file(credentialsId: 'sfdc-jwt-key', variable: 'JWT_KEY_FILE')
        ]) {

            def SFDC_HOST   = 'https://login.salesforce.com'
            def DEV_ORG_ALIAS = 'projectdemosfdc'
            def reportDir   = 'pmd-report-html'
            def htmlReport  = "${reportDir}/StaticAnalysisReport.html"
            def sarifReport = "${reportDir}/pmd-report.sarif"

            stage('Clean Workspace') {
                cleanWs()
                echo "Workspace cleaned successfully!"
            }

            stage('Checkout Source') {
                checkout scm
            }

            stage('Static Code Analysis') {
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

            stage('Publish Reports') {
                // Archive raw reports
                archiveArtifacts artifacts: "${reportDir}/**", fingerprint: true

                // Publish HTML report in Jenkins UI
                publishHTML(target: [
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: reportDir,
                    reportFiles: 'StaticAnalysisReport.html',
                    reportName: 'Salesforce Static Analysis Report'
                ])

                // Publish SARIF report to Warnings NG + Quality Gates
                recordIssues(
                    tools: [sarif(
                        name: 'Salesforce Code Analyzer',
                        pattern: "${sarifReport}"
                    )],
                    qualityGates: [
                        [threshold: 1, type: 'TOTAL_ERROR', unstable: false],  // fail if any error
                        [threshold: 1, type: 'TOTAL_HIGH',  unstable: false],  // fail if any high
                        [threshold: 5, type: 'TOTAL_NORMAL', unstable: true]   // unstable if >=5 medium
                    ]
                )
            }

            stage('Authenticate Dev Org') { 
                authenticateOrg(DEV_ORG_ALIAS, SFDC_HOST, CONNECTED_APP_CONSUMER_KEY, JWT_KEY_FILE, SFDC_USERNAME)
            }

            stage('Deploy to Dev Org') { 
                deployToOrg(DEV_ORG_ALIAS)
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
