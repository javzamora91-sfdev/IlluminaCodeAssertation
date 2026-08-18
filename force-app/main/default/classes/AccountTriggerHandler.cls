public with sharing class AccountTriggerHandler {
public static void handleAfterInsertUpdate(List<Account> newAccounts, Map<Id, Account> oldMap) {
        List<Account_Risk_Event__e> eventsToPublish = new List<Account_Risk_Event__e>();

        for (Account acc : newAccounts) {
            Boolean isHighRisk = (acc.Risk__c == 'High');
            Boolean isNewAndHigh = (oldMap == null && isHighRisk);
            Boolean isChangedToHigh = (oldMap != null && isHighRisk && oldMap.get(acc.Id).Risk__c != 'High');

            if (isNewAndHigh || isChangedToHigh) {
                eventsToPublish.add(new Account_Risk_Event__e(
                    Account_Id__c = acc.Id,
                    Account_Name__c = acc.Name,
                    Account_Owner_Id__c = acc.OwnerId
                ));
            }
        }

        if (!eventsToPublish.isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(eventsToPublish);
            handlePublishResults(results);
        }
    }

    private static void handlePublishResults(List<Database.SaveResult> results) {
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    System.debug(LoggingLevel.ERROR, 'Platform Event Publish Error: ' + err.getMessage());
                }
            }
        }
    }
}