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
    try {
        withCredentials([
            string(credentialsId: 'sfdc-consumer-key', variable: 'CONNECTED_APP_CONSUMER_KEY'),
            string(credentialsId: 'sfdc-username', variable: 'SFDC_USERNAME'),
            file(credentialsId: 'sfdc-jwt-key', variable: 'JWT_KEY_FILE')
        ]) {

            def SFDC_HOST = 'https://login.salesforce.com'
            def DEV_ORG_ALIAS = 'dev'
            def reportDir = 'pmd-report-html'
            def rulesetFile = 'apex-ruleset.xml' // Place this in repo root or workspace

            stage('Clean Workspace') {
                cleanWs()
                echo "✅ Workspace cleaned successfully!"
            }

            stage('Checkout Source') {
                checkout scm
            }

            stage('Install PMD CLI') {
                if (isUnix()) {
                    sh '''
                        if ! command -v pmd >/dev/null 2>&1; then
                            echo "Installing PMD CLI..."
                            wget https://github.com/pmd/pmd/releases/download/pmd_releases%2F7.55.0/pmd-bin-7.55.0.zip -O pmd.zip
                            unzip pmd.zip -d pmd
                            export PATH=$PWD/pmd/bin:$PATH
                        else
                            echo "PMD CLI already installed."
                            pmd -version
                        fi
                    '''
                } else {
                    bat '''
                        REM Assume PMD zip is pre-downloaded on Windows agent
                        if not exist "pmd" mkdir pmd
                        REM Add pmd/bin to PATH
                        set PATH=%CD%\\pmd\\bin;%PATH%
                        pmd.bat -version
                    '''
                }
            }

            stage('Static Code Analysis') {
                echo "🚀 Running PMD analysis on Apex classes..."

                if (isUnix()) {
                    sh """
                        rm -rf "${reportDir}" || true
                        mkdir -p "${reportDir}"

                        # Generate reports
                        pmd -d force-app/main/default/classes -R ${rulesetFile} -f text -r pmd-report.txt
                        pmd -d force-app/main/default/classes -R ${rulesetFile} -f xml -r pmd-report.xml
                        pmd -d force-app/main/default/classes -R ${rulesetFile} -f html -r ${reportDir}/index.html

                        # Ensure index.html exists
                        [ ! -f "${reportDir}/index.html" ] && echo "<html><body><h1>No PMD report generated</h1></body></html>" > "${reportDir}/index.html"

                        ls -l pmd-report.*
                        ls -l "${reportDir}"
                    """
                } else {
                    bat """
                        if exist "${reportDir}" rmdir /s /q "${reportDir}"
                        mkdir "${reportDir}"

                        REM Run PMD scanner on Windows
                        pmd.bat -d force-app\\main\\default\\classes -R ${rulesetFile} -f text -r pmd-report.txt
                        pmd.bat -d force-app\\main\\default\\classes -R ${rulesetFile} -f xml -r pmd-report.xml
                        pmd.bat -d force-app\\main\\default\\classes -R ${rulesetFile} -f html -r ${reportDir}\\index.html

                        REM Ensure index.html exists
                        if not exist "${reportDir}\\index.html" echo "<html><body><h1>No PMD report generated</h1></body></html>" > "${reportDir}\\index.html"

                        dir /b pmd-report.*
                        dir /b ${reportDir}
                        timeout /t 2
                    """
                }

                archiveArtifacts artifacts: 'pmd-report.*', allowEmptyArchive: true

                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: reportDir,
                    reportFiles: 'index.html',
                    reportName: "PMD Static Analysis Report"
                ])

                echo "✅ PMD analysis completed. HTML report published."
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
