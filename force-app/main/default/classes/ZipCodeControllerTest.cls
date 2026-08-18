@isTest
private class ZipCodeControllerTest {

    @isTest
    static void testGetUSZipCodeSuccess() {
        Test.setMock(HttpCalloutMock.class, new ZippopotamCalloutMock(200, 'US'));

        Test.startTest();
        ZipCodeController.ZipCodeWrapper result = ZipCodeController.getZipCodeDetails('us', '60137');
        Test.stopTest();
    

        System.assertNotEquals(null, result, 'Expected non-null result from controller');
        System.assertEquals('US', result.countryAbbreviation, 'Country abbreviation should be US');
        System.assertEquals('Glen Ellyn', result.places[0].placeName, 'Place name should match mock data');

        // Verify NO record was logged for US lookups
        List<ZipCode_Log__c> logs = [SELECT Id FROM ZipCode_Log__c];
        System.assertEquals(0, logs.size(), 'US lookups should not create database log records');
    }

    @isTest
    static void testGetNonUSZipCodeSuccessAndLogging() {
        Test.setMock(HttpCalloutMock.class, new ZippopotamCalloutMock(200, 'MX'));

        Test.startTest();
        ZipCodeController.ZipCodeWrapper result = ZipCodeController.getZipCodeDetails('mx', '60137');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected non-null result from controller');
        System.assertEquals('MX', result.countryAbbreviation, 'Country abbreviation should be MX');

        // Verify Non-US record was logged to database
        List<ZipCode_Log__c> logs = [SELECT Id, ZipCode__c, Country__c, State__c, Place_Name__c FROM ZipCode_Log__c];
        System.assertEquals(1, logs.size(), 'Non-US lookups must insert a record into ZipCode_Log__c');
        System.assertEquals('60137', logs[0].ZipCode__c, 'Logged zip code should match');
        System.assertEquals('Mexico', logs[0].Country__c, 'Logged country should match');
    }

    @isTest
    static void test404NotFoundException() {
        Test.setMock(HttpCalloutMock.class, new ZippopotamCalloutMock(404, ''));

        Test.startTest();
        try {
            ZipCodeController.getZipCodeDetails('us', '9999999');
            System.assert(false, 'Expected AuraHandledException on 404 response');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('not found'), 'Exception message should indicate zip code was not found');
        }
        Test.stopTest();
    }
    @isTest
    static void test500ServerErrorException() {
        // Mock a 500 Internal Server Error to cover the general "else" status code branch
        Test.setMock(HttpCalloutMock.class, new ZippopotamCalloutMock(500, ''));

        Test.startTest();
        try {
            ZipCodeController.getZipCodeDetails('us', '60137');
            System.assert(false, 'Expected AuraHandledException on 500 response');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('API Error: Received status code 500'), 'Exception should contain status code 500');
        }
        Test.stopTest();
    }

    @isTest
    static void testInvalidJSONHandling() {
        // Mock a 200 response with malformed JSON to trigger the general catch block
        SingleRequestMock mock = new SingleRequestMock(200, 'OK', 'INVALID_JSON_BODY', null);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        try {
            ZipCodeController.getZipCodeDetails('us', '60137');
            System.assert(false, 'Expected AuraHandledException on malformed JSON');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Failed to process request'), 'Exception message should cover catch block');
        }
        Test.stopTest();
    }
    @isTest
    static void testBlankZipCodeValidation() {
        Test.startTest();
        try {
            ZipCodeController.getZipCodeDetails('us', '');
            System.assert(false, 'Expected exception on blank zip code input');
        } catch (AuraHandledException e) {
            System.assertEquals('Zip code cannot be blank.', e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGetNonUSLogs() {
        // Insert dummy log record
        insert new ZipCode_Log__c(
            ZipCode__c = '75001',
            Country__c = 'France',
            State__c = 'Ile-de-France',
            Place_Name__c = 'Paris 01'
        );

        Test.startTest();
        List<ZipCode_Log__c> logs = ZipCodeController.getNonUSLogs();
        Test.stopTest();

        System.assertEquals(1, logs.size(), 'Expected 1 record returned from getNonUSLogs');
        System.assertEquals('75001', logs[0].ZipCode__c, 'Returned zip code should match');
    }

    @isTest
    static void testLongPlaceNamesTruncationAndLogging() {
        // Mock response with multiple long place names exceeding 255 characters total
        String longName1 = 'A'.repeat(150);
        String longName2 = 'B'.repeat(150);

        SingleRequestMock mock = new SingleRequestMock(200, 'OK', '{' +
            '"post code": "75001",' +
            '"country": "France",' +
            '"country abbreviation": "FR",' +
            '"places": [{' +
                '"place name": "' + longName1 + '",' +
                '"state": "Ile-de-France",' +
                '"state abbreviation": "IDF"' +
            '}, {' +
                '"place name": "' + longName2 + '",' +
                '"state": "Ile-de-France",' +
                '"state abbreviation": "IDF"' +
            '}]' +
        '}', null);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        ZipCodeController.ZipCodeWrapper result = ZipCodeController.getZipCodeDetails('fr', '75001');
        Test.stopTest();

        ZipCode_Log__c log = [SELECT Place_Name__c FROM ZipCode_Log__c LIMIT 1];
        System.assertEquals(255, log.Place_Name__c.length(), 'Place name should be truncated to 255 chars');
        System.assert(log.Place_Name__c.endsWith('...'), 'Truncated place name should end with ellipsis');
    }

    @isTest
    static void testEmptyPlaceNamesHandling() {
        // Mock response with places array containing empty/blank strings
        SingleRequestMock mock = new SingleRequestMock(200, 'OK', '{' +
            '"post code": "12345",' +
            '"country": "Germany",' +
            '"country abbreviation": "DE",' +
            '"places": [{' +
                '"place name": "",' +
                '"state": "Bavaria",' +
                '"state abbreviation": "BY"' +
            '}]' +
        '}', null);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        ZipCodeController.ZipCodeWrapper result = ZipCodeController.getZipCodeDetails('de', '12345');
        Test.stopTest();

        ZipCode_Log__c log = [SELECT Place_Name__c FROM ZipCode_Log__c LIMIT 1];
        System.assert(
            String.isBlank(log.Place_Name__c), 
            'Place name should be blank or empty when no valid place names are provided'
        );
    }
    @isTest
    static void testNullCountryCodeDefaultsToUS() {
        Test.setMock(HttpCalloutMock.class, new ZippopotamCalloutMock(200, 'US'));

        Test.startTest();
        // Passing null for countryCode executes the ternary fallback branch
        ZipCodeController.ZipCodeWrapper result = ZipCodeController.getZipCodeDetails(null, '60137');
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals('US', result.countryAbbreviation);
    }

    @isTest
    static void testSaveNonUSZipLogDMLException() {
        // Mock a successful non-US response to force saveNonUSZipLog to run
        Test.setMock(HttpCalloutMock.class, new ZippopotamCalloutMock(200, 'MX'));

        // Run as a restricted user without create access on Zip_Code_Log__c to force an insert exception
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];
        User restrictedUser = new User(
            Alias = 'noaccess',
            Email = 'noaccess@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'noaccess' + DateTime.now().getTime() + '@testorg.com'
        );

        System.runAs(restrictedUser) {
            Test.startTest();
            try {
                ZipCodeController.getZipCodeDetails('mx', '60137');
                System.assert(false, 'Expected AuraHandledException due to DML insert failure');
            } catch (AuraHandledException e) {
                System.assert(
                    e.getMessage().contains('Error saving non-US Zip Code log'),
                    'Should hit the catch block inside saveNonUSZipLog'
                );
            }
            Test.stopTest();
        }
    }
    @isTest
    static void testWrapperPropertiesDirectAccess() {
        // Explicitly invoke getters and setters to execute property accessors
        ZipCodeController.PlaceWrapper place = new ZipCodeController.PlaceWrapper();
        place.stateAbbreviation = 'IL';
        place.latitude = '41.8661';
        place.longitude = '-88.0648';

        System.assertEquals('IL', place.stateAbbreviation);
        System.assertEquals('41.8661', place.latitude);
        System.assertEquals('-88.0648', place.longitude);
    }    
}