public class sampleApexClass {

    public static void processAccounts(List<Account> accounts) {
        if (accounts == null || accounts.isEmpty()) {
            return;
        }

        // Collect account Ids
        Set<Id> accIds = new Set<Id>();
        for (Account acc : accounts) {
            accIds.add(acc.Id);
        }

        // Query all contacts at once
        Map<Id, List<Contact>> accIdToContacts = new Map<Id, List<Contact>>();
        for (Contact con : [
            SELECT Id, Name, AccountId
            FROM Contact
            WHERE AccountId IN :accIds
        ]) {
            if (!accIdToContacts.containsKey(con.AccountId)) {
                accIdToContacts.put(con.AccountId, new List<Contact>());
            }
            accIdToContacts.get(con.AccountId).add(con);
        }

        // Debug counts
        for (Account acc : accounts) {
            Integer size = accIdToContacts.containsKey(acc.Id) ? accIdToContacts.get(acc.Id).size() : 0;
            System.debug('Contacts for ' + acc.Name + ': ' + size);
        }

        // Safe exception handling
        try {
            Integer result = 10 / 0;
        } catch (Exception e) {
            System.debug('Handled exception: ' + e.getMessage());
        }

        // Bulk update
        for (Account acc : accounts) {
            acc.Description = 'Updated by static analysis example';
        }
        update accounts;
    }

    public void complexMethod(String param1, Integer param2, Boolean param3, Decimal param4, Date param5) {
        System.debug('Complex method called');
    }

    public String getGreeting(String name) {
        if (String.isBlank(name)) {
            return 'Hello, Guest!';
        } else {
            return 'Hello, ' + name + '!';
        }
    }
}
