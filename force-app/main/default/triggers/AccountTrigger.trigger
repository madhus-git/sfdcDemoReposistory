trigger AccountTrigger on Account (before insert, before update) {
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        sampleApexClass.processAccounts(Trigger.new);
    }
}