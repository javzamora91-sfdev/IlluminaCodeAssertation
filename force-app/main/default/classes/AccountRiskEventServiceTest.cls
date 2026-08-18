@isTest
private class AccountRiskEventServiceTest {

    @isTest
    static void testEventProcessingCreatesCaseWithDifferentOwner() {
        // 1. Create a specific alternate standard user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User alternateUser = new User(
            Alias = 'altusr',
            Email = 'altuser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Alternate',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'altuser' + DateTime.now().getTime() + '@testorg.com'
        );
        insert alternateUser;

        Account acc = new Account(Name = 'Test Risk Account');
        insert acc;

        // 2. Exclude ALL other active users except alternateUser by marking running user + others as account owners
        // Or simply publish event with running user as owner
        Account_Risk_Event__e evt = new Account_Risk_Event__e(
            Account_Id__c = acc.Id,
            Account_Name__c = acc.Name,
            Account_Owner_Id__c = UserInfo.getUserId()
        );

        Test.startTest();
        EventBus.publish(evt);
        Test.stopTest();

        // 3. Verify case exists and owner != Account Owner
        List<Case> createdCases = [SELECT Id, AccountId, OwnerId FROM Case WHERE AccountId = :acc.Id];
        System.assertEquals(1, createdCases.size(), 'One case should be created from the platform event');
        System.assertNotEquals(UserInfo.getUserId(), createdCases[0].OwnerId, 'Case owner cannot be the account owner');
    }

    @isTest
    static void testEventProcessingNoAlternateUserLeavesCaseUncreated() {
        Account acc = new Account(Name = 'Isolated Owner Account');
        insert acc;

        // Query ALL active users in the org to exclude every single one of them
        List<User> allActiveUsers = [SELECT Id FROM User WHERE IsActive = true];
        
        List<Account_Risk_Event__e> events = new List<Account_Risk_Event__e>();
        
        // We pass an event where Account_Owner_Id__c is populated, but we test service directly
        // using an event payload that treats all active users as "excluded"
        Account_Risk_Event__e evt = new Account_Risk_Event__e(
            Account_Id__c = acc.Id,
            Account_Name__c = acc.Name,
            Account_Owner_Id__c = UserInfo.getUserId()
        );

        Test.startTest();
        // Force the service to process with all active user IDs passed in the excluded set
        // By invoking processEventsForTesting or passing all active user IDs as account owners across multi-event list
        List<Account_Risk_Event__e> fullExcludedEvents = new List<Account_Risk_Event__e>();
        for (User u : allActiveUsers) {
            fullExcludedEvents.add(new Account_Risk_Event__e(
                Account_Id__c = acc.Id,
                Account_Name__c = acc.Name,
                Account_Owner_Id__c = u.Id
            ));
        }

        AccountRiskEventService.processEvents(fullExcludedEvents);
        Test.stopTest();

        List<Case> createdCases = [SELECT Id FROM Case WHERE AccountId = :acc.Id];
        System.assertEquals(0, createdCases.size(), 'Case must be left uncreated if no other active user exists');
    }
}