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
                echo "🔎 Running Static Code Analysis..."

                if (isUnix()) {
                    sh """
                        mkdir -p ${reportDir}

                        # Generate HTML report
                        sf scanner:run --target "force-app/main/default/classes" \
                                       --engine pmd \
                                       --format html \
                                       --outfile ${htmlReport} || true

                        # Generate JSON report for quality gate
                        sf scanner:run --target "force-app/main/default/classes" \
                                       --engine pmd \
                                       --format json \
                                       --outfile ${jsonReport} || true
                    """
                } else {
                    bat """
                        if not exist ${reportDir} mkdir ${reportDir}
                        set PATH=%APPDATA%\\npm;%PATH%

                        sf scanner:run --target "force-app/main/default/classes" ^
                                       --engine pmd ^
                                       --format html ^
                                       --outfile ${htmlReport} || exit 0

                        sf scanner:run --target "force-app/main/default/classes" ^
                                       --engine pmd ^
                                       --format json ^
                                       --outfile ${jsonReport} || exit 0
                    """
                }

                // -----------------------------
                // Publish HTML report in Jenkins UI
                // -----------------------------
                if (fileExists(htmlReport)) {
                    archiveArtifacts artifacts: "${reportDir}/**", fingerprint: true

                    publishHTML(target: [
                        reportDir: "${reportDir}",
                        reportFiles: "StaticAnalysisReport.html",
                        reportName: "Static Code Analysis Report",
                        keepAll: true,
                        alwaysLinkToLastBuild: true,
                        allowMissing: false
                    ])
                    echo "✅ Static analysis report published in Jenkins UI."
                } else {
                    error "⚠️ No static analysis report generated!"
                }

                // -----------------------------
                // Quality Gate: Fail build if violations exist
                // -----------------------------
                if (fileExists(jsonReport)) {
                    def jsonContent = readFile(jsonReport)
                    def json = readJSON text: jsonContent
                    def violationsCount = json.issues.size()
                    if (violationsCount > 0) {
                        error "❌ Static analysis failed! Found ${violationsCount} PMD violations."
                    } else {
                        echo "✅ No PMD violations found."
                    }
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
