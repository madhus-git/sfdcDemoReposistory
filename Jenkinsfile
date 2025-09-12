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
                echo "🔎 Running PMD Static Code Analysis..."

                if (isUnix()) {
                    sh """
                        mkdir -p ${reportDir}

                        # Run PMD XML report
                        cd "${env.WORKSPACE}"
                        sf scanner:run --target "force-app/main/default/classes" \
                                       --engine pmd \
                                       --format xml \
                                       --outfile "${xmlReport}" || true
                    """
                } else {
                    bat """
                        if not exist "${reportDir}" mkdir "${reportDir}"
                        cd "%WORKSPACE%"
                        sf scanner:run --target "force-app/main/default/classes" ^
                                       --engine pmd ^
                                       --format xml ^
                                       --outfile "${xmlReport}" || exit 0
                    """
                }

                // ------------------------
                // Publish PMD XML in Jenkins UI
                // ------------------------
                if (fileExists(xmlReport)) {
                    archiveArtifacts artifacts: "${reportDir}/**", fingerprint: true

                    recordIssues(
                        tools: [pmd(pattern: xmlReport)],
                        skipFailedBuild: false
                    )

                    echo "✅ PMD analysis published in Jenkins UI."
                } else {
                    error "⚠️ PMD XML report not found! Check Salesforce CLI and working directory."
                }
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
