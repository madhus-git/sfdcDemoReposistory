// ==============================
// Main Pipeline
// ==============================
node {
    try {
                // --------------------------
                // Checkout Source
                // --------------------------
                stage('Checkout Source') {
                    checkout scm
                }

                
        
    } catch (err) {
        echo "Pipeline failed: ${err}"
        currentBuild.result = 'FAILURE'
        throw err
    }
}
