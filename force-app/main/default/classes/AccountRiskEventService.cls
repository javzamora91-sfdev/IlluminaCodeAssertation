public with sharing class AccountRiskEventService {

    public static void processEvents(List<Account_Risk_Event__e> events) {
        Set<Id> accountOwnerIds = new Set<Id>();
        for (Account_Risk_Event__e evt : events) {
            if (String.isNotBlank(evt.Account_Owner_Id__c)) {
                accountOwnerIds.add((Id) evt.Account_Owner_Id__c);
            }
        }

        // Query active fallback user who is not one of the account owners
        Id fallbackUserId = getFallbackUserId(accountOwnerIds);
        if (fallbackUserId == null) {
            System.debug(LoggingLevel.ERROR, 'No active alternate owner available for Case assignment.');
            return;
        }

        List<Case> casesToInsert = new List<Case>();
        for (Account_Risk_Event__e evt : events) {
            casesToInsert.add(new Case(
                AccountId = evt.Account_Id__c,
                Subject = 'High Risk Account Review: ' + evt.Account_Name__c,
                Description = 'Automated case generated via Platform Event due to High Risk selection.',
                Status = 'New',
                Origin = 'Automated Event',
                OwnerId = fallbackUserId
            ));
        }

        if (!casesToInsert.isEmpty()) {
            List<Database.SaveResult> srList = Database.insert(casesToInsert, false);
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'Case Creation Error: ' + err.getMessage());
                    }
                }
            }
        }
    }

    private static Id getFallbackUserId(Set<Id> excludedUserIds) {
        List<User> fallbackUsers = [
            SELECT Id 
            FROM User 
            WHERE IsActive = true 
              AND Id NOT IN :excludedUserIds 
              AND UserType = 'Standard'
            WITH USER_MODE
            LIMIT 1
        ];
        return fallbackUsers.isEmpty() ? null : fallbackUsers[0].Id;
    }
}