trigger AccountTrigger on Account (after insert, after update) {
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        sampleApexClass.processAccounts(Trigger.new);
    }
}