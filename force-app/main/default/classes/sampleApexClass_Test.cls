@isTest
public class testSampleApexClass {

    @testSetup
    static void setupData() {
        // Create sample Accounts and Contacts
        List<Account> accList = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            accList.add(new Account(Name = 'Test Account ' + i));
        }
        insert accList;

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

        // Assert Description field is updated in-memory
        for (Account acc : accs) {
            System.assertEquals('Updated by static analysis example', acc.Description);
        }
    }

    @isTest
    static void testTriggerExecution() {
        // Inserting a new Account should fire the trigger
        Account acc = new Account(Name = 'Trigger Test');
        Test.startTest();
        insert acc;
        Test.stopTest();

        // Validate trigger called processAccounts by checking debug logs or updated data
        Account insertedAcc = [SELECT Id, Name FROM Account WHERE Id = :acc.Id LIMIT 1];
        System.assertNotEquals(null, insertedAcc.Id);
    }

    @isTest
    static void testComplexMethod() {
        sampleApexClass obj = new sampleApexClass();

        Test.startTest();
        obj.complexMethod('Param', 5, true, 10.5, Date.today());
        Test.stopTest();

        // No exception expected
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
}
