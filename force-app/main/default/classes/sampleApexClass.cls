public class SampleStaticAnalysisClass {

    // Unused private variable - PMD will flag this
    private String unusedVariable = 'Hello'; 

    public static void processAccounts(List<Account> accounts) {
        // SOQL query inside a loop - PMD will flag this as a performance issue
        for (Account acc : accounts) {
            List<Contact> contacts = [SELECT Id, Name FROM Contact WHERE AccountId = :acc.Id];
            System.debug('Contacts for ' + acc.Name + ': ' + contacts.size());
        }

        // Empty catch block - PMD will flag this as a potential issue
        try {
            // Some operation that might throw an exception
            Integer result = 10 / 0; 
        } catch (Exception e) {
            // This catch block is empty and doesn't handle the exception
        }

        // Hardcoded ID - PMD might flag this if it's not a known system ID
        Id hardcodedId = '001xxxxxxxxxxxx'; 

        // DML operation inside a loop - PMD will flag this
        List<Account> accountsToUpdate = new List<Account>();
        for (Account acc : accounts) {
            acc.Description = 'Updated by static analysis example';
            accountsToUpdate.add(acc);
        }
        // This should be outside the loop
        // update accountsToUpdate; 
    }

    // Method with too many parameters - PMD might flag this for complexity
    public void complexMethod(String param1, Integer param2, Boolean param3, Decimal param4, Date param5) {
        System.debug('Complex method called');
    }

    // Method with low code coverage potential - requires a test class
    public String getGreeting(String name) {
        if (String.isBlank(name)) {
            return 'Hello, Guest!';
        } else {
            return 'Hello, ' + name + '!';
        }
    }
}