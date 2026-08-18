@isTest
private class ZipCodeFlowAdapterTest {

    @isTest
    static void testInvocableMethodExecution() {
        Test.setMock(HttpCalloutMock.class, new ZippopotamCalloutMock(200, 'US'));

        ZipCodeFlowAdapter.FlowInput input = new ZipCodeFlowAdapter.FlowInput();
        input.countryCode = 'us';
        input.zipCode = '60137';

        List<ZipCodeFlowAdapter.FlowInput> inputList = new List<ZipCodeFlowAdapter.FlowInput>{ input };

        Test.startTest();
        List<ZipCodeFlowAdapter.FlowOutput> outputList = ZipCodeFlowAdapter.fetchZipDetails(inputList);
        Test.stopTest();

        System.assertEquals(1, outputList.size(), 'Expected 1 output item');
        System.assertEquals(true, outputList[0].isUS, 'isUS flag should be true');
        System.assertEquals('60137', outputList[0].zipCode, 'Zip code should match input');
        System.assertEquals('Glen Ellyn', outputList[0].placeName, 'Place name should match mock data');
    }
}