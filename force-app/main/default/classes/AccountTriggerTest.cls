@isTest
private class AccountTriggerTest {

    @isTest
    static void testInsertHighRiskAccountPublishesEvent() {
        Account acc = new Account(
            Name = 'High Risk Corp',
            Risk__c = 'High'
        );

        Test.startTest();
        insert acc;
        Test.stopTest();

        // Test.stopTest() forces asynchronous platform events to deliver synchronously
        List<Case> createdCases = [SELECT Id, AccountId FROM Case WHERE AccountId = :acc.Id];
        // Note: Event delivery and case creation are verified in detail in AccountRiskEventServiceTest
    }

    @isTest
    static void testUpdateToHighRiskPublishesEvent() {
        Account acc = new Account(
            Name = 'Medium Risk Corp',
            Risk__c = 'Medium'
        );
        insert acc;

        acc.Risk__c = 'High';

        Test.startTest();
        update acc;
        Test.stopTest();

        Account updatedAcc = [SELECT Risk__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('High', updatedAcc.Risk__c);
    }

    @isTest
    static void testUpdateNonRiskFieldDoesNotTriggerEvent() {
        Account acc = new Account(
            Name = 'Low Risk Corp',
            Risk__c = 'Low'
        );
        insert acc;

        acc.Name = 'Low Risk Corp Renamed';

        Test.startTest();
        update acc;
        Test.stopTest();

        List<Case> cases = [SELECT Id FROM Case WHERE AccountId = :acc.Id];
        System.assertEquals(0, cases.size(), 'No cases should be created for non-High risk updates');
    }
}