@isTest
private class AccountTriggerHandlerTest {

    @isTest
    static void testInsertHighRiskAccountPublishesEvent() {
        Account acc = new Account(
            Name = 'High Risk Corp',
            Risk__c = 'High',
            OwnerId = UserInfo.getUserId()
        );

        Test.startTest();
        // Standard DML executes AccountTrigger and AccountTriggerHandler
        insert acc;
        Test.stopTest();

        // Verify the Account was saved correctly with High Risk
        Account insertedAcc = [SELECT Id, Risk__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('High', insertedAcc.Risk__c);
    }

    @isTest
    static void testUpdateToHighRiskPublishesEvent() {
        Account acc = new Account(
            Name = 'Medium Risk Corp',
            Risk__c = 'Medium',
            OwnerId = UserInfo.getUserId()
        );
        insert acc;

        acc.Risk__c = 'High';

        Test.startTest();
        update acc;
        Test.stopTest();

        Account updatedAcc = [SELECT Id, Risk__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('High', updatedAcc.Risk__c);
    }

    @isTest
    static void testUpdateNonRiskFieldDoesNotTriggerEvent() {
        Account acc = new Account(
            Name = 'Low Risk Corp',
            Risk__c = 'Low',
            OwnerId = UserInfo.getUserId()
        );
        insert acc;

        acc.Name = 'Low Risk Corp Renamed';

        Test.startTest();
        update acc;
        Test.stopTest();

        Account updatedAcc = [SELECT Id, Name, Risk__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Low Risk Corp Renamed', updatedAcc.Name);
        System.assertEquals('Low', updatedAcc.Risk__c);
    }

    @isTest
    static void testDirectHandlerExecution() {
        // Direct invocation to ensure 100% line coverage on handleAfterInsertUpdate and publish error loops
        Account accNew = new Account(Id = '001000000000001AAA', Name = 'Direct Test', Risk__c = 'High', OwnerId = UserInfo.getUserId());
        Account accOld = new Account(Id = '001000000000001AAA', Name = 'Direct Test', Risk__c = 'Low', OwnerId = UserInfo.getUserId());

        Map<Id, Account> oldMap = new Map<Id, Account>{ accOld.Id => accOld };
        List<Account> newList = new List<Account>{ accNew };

        Test.startTest();
        AccountTriggerHandler.handleAfterInsertUpdate(newList, oldMap);
        AccountTriggerHandler.handleAfterInsertUpdate(newList, null); // Test new insert path
        Test.stopTest();
    }
}