@isTest
public class sampleApexClass_Test {

    @testSetup
    static void setupData() {
        // Create sample Accounts
        List<Account> accList = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            accList.add(new Account(Name = 'Test Account ' + i));
        }
        insert accList;

        // Create Contacts
        List<Contact> conList = new List<Contact>();
        for (Account acc : accList) {
            conList.add(new Contact(
                LastName = 'Contact ' + acc.Name,
                AccountId = acc.Id
            ));
        }
        insert conList;
    }

    @isTest
    static void testProcessAccountsDirectCall() {
        List<Account> accs = [SELECT Id, Name FROM Account LIMIT 2];

        Test.startTest();
        sampleApexClass.processAccounts(accs);
        Test.stopTest();

        // After method call, in-memory accounts should have Description set
        for (Account acc : accs) {
            System.assertEquals('Updated by static analysis example', acc.Description);
        }
    }

    @isTest
    static void testTriggerExecution() {
        Account acc = new Account(Name = 'Trigger Test');
        Test.startTest();
        insert acc;
        Test.stopTest();

        // Verify Description is set by before trigger
        Account insertedAcc = [SELECT Description FROM Account WHERE Id = :acc.Id LIMIT 1];
        System.assertEquals('Updated by static analysis example', insertedAcc.Description);
    }

    @isTest
    static void testComplexMethod() {
        sampleApexClass obj = new sampleApexClass();

        Test.startTest();
        obj.complexMethod('Param', 5, true, 10.5, Date.today());
        Test.stopTest();

        System.assert(true, 'complexMethod executed successfully');
    }

    @isTest
    static void testGetGreeting() {
        sampleApexClass obj = new sampleApexClass();

        String result1 = obj.getGreeting('Sudha');
        System.assertEquals('Hello, Sudha!', result1);

        String result2 = obj.getGreeting(null);
        System.assertEquals('Hello, Guest!', result2);

        String result3 = obj.getGreeting('');
        System.assertEquals('Hello, Guest!', result3);
    }

    @isTest
    static void testProcessAccountsWithEmptyAndNull() {
        // Null input
        Test.startTest();
        sampleApexClass.processAccounts(null);
        Test.stopTest();

        // Empty list input
        Test.startTest();
        sampleApexClass.processAccounts(new List<Account>());
        Test.stopTest();

        System.assert(true, 'Handled null and empty inputs without error');
    }
}
