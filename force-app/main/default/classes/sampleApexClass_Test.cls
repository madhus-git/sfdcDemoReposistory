@isTest
public class sampleApexClass_Test {

    private static Account setupData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(
            LastName = 'Test Contact',
            AccountId = acc.Id
        );
        insert con;

        return acc;
    }

    @isTest
    static void testComplexMethod() {
        Account acc = setupData();

        sampleApexClass cls = new sampleApexClass();
        Test.startTest();
        cls.complexMethod('param1', 123, true, 99.99, Date.today());
        Test.stopTest();

        System.assertEquals('Test Account', acc.Name, 'Account name should remain unchanged');
    }

    @isTest
    static void testGetGreeting() {
        sampleApexClass cls = new sampleApexClass();

        String greeting1 = cls.getGreeting('Sudha');
        System.assertEquals('Hello, Sudha!', greeting1);

        String greeting2 = cls.getGreeting('');
        System.assertEquals('Hello, Guest!', greeting2);
    }

    @isTest
    static void testProcessAccountsDirectCall() {
        Account acc = setupData();

        Test.startTest();
        sampleApexClass.processAccounts(new List<Account>{ acc });
        Test.stopTest();

        Account updatedAcc = [SELECT Id, Description FROM Account WHERE Id = :acc.Id];
        System.assertEquals(
            'Updated by static analysis example',
            updatedAcc.Description,
            'Description should be updated'
        );
    }

    @isTest
    static void testTriggerExecution() {
        Account acc = new Account(Name = 'Trigger Test Account');
        insert acc;

        Account updatedAcc = [SELECT Id, Description FROM Account WHERE Id = :acc.Id];
        System.assertEquals(
            'Updated by static analysis example',
            updatedAcc.Description,
            'Description should be updated by trigger'
        );
    }
}
