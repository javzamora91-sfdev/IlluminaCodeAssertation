public with sharing class ZipCodeController {

    public class ZipCodeWrapper {
        @AuraEnabled public String postCode { get; set; }
        @AuraEnabled public String country { get; set; }
        @AuraEnabled public String countryAbbreviation { get; set; }
        @AuraEnabled public List<PlaceWrapper> places { get; set; }
    }

    public class PlaceWrapper {
        @AuraEnabled public String placeName { get; set; }
        @AuraEnabled public String state { get; set; }
        @AuraEnabled public String stateAbbreviation { get; set; }
        @AuraEnabled public String latitude { get; set; }
        @AuraEnabled public String longitude { get; set; }
    }

    @AuraEnabled
    public static ZipCodeWrapper getZipCodeDetails(String countryCode, String zipCode) {
        if (String.isBlank(zipCode)) {
            throw createAuraException('Zip code cannot be blank.');
        }

        countryCode = String.isBlank(countryCode) ? 'us' : countryCode.toLowerCase();
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Zippopotam_API/' + EncodingUtil.urlEncode(countryCode, 'UTF-8') + '/' + EncodingUtil.urlEncode(zipCode.trim(), 'UTF-8'));
        request.setMethod('GET');
        request.setTimeout(10000);

        try {
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                String jsonBody = response.getBody()
                    .replace('"post code"', '"postCode"')
                    .replace('"country abbreviation"', '"countryAbbreviation"')
                    .replace('"place name"', '"placeName"')
                    .replace('"state abbreviation"', '"stateAbbreviation"');

                ZipCodeWrapper result = (ZipCodeWrapper) JSON.deserialize(jsonBody, ZipCodeWrapper.class);

                if (result != null && !'US'.equalsIgnoreCase(result.countryAbbreviation)) {
                    saveNonUSZipLog(result);
                }

                return result;
            } else if (response.getStatusCode() == 404) {
                throw createAuraException('Zip Code "' + zipCode + '" not found for country code ' + countryCode.toUpperCase() + '.');
            } else {
                throw createAuraException('API Error: Received status code ' + response.getStatusCode());
            }
        } catch (AuraHandledException ahe) {
            throw ahe; // Rethrow intended AuraHandledExceptions
        } catch (Exception ex) {
            throw createAuraException('Failed to process request: ' + ex.getMessage());
        }
    }

    private static void saveNonUSZipLog(ZipCodeWrapper wrapper) {
        try {
            List<String> placeNames = new List<String>();
            String stateName = '';

            if (wrapper.places != null && !wrapper.places.isEmpty()) {
                stateName = wrapper.places[0].state;
                for (PlaceWrapper p : wrapper.places) {
                    if (String.isNotBlank(p.placeName)) {
                        placeNames.add(p.placeName);
                    }
                }
            }

            String concatenatedPlaces = String.join(placeNames, ', ');
            if (concatenatedPlaces.length() > 255) {
                concatenatedPlaces = concatenatedPlaces.substring(0, 252) + '...';
            }

            ZipCode_Log__c log = new ZipCode_Log__c(
                ZipCode__c = wrapper.postCode,
                Country__c = wrapper.country,
                State__c = stateName,
                Place_Name__c = concatenatedPlaces
            );
            insert as user log;
        } catch (Exception ex) {
            throw createAuraException('Error saving non-US Zip Code log: ' + ex.getMessage());
        }
    }

    // Helper method to properly pass custom error text to LWC
    private static AuraHandledException createAuraException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }

    @AuraEnabled(cacheable=true)
    public static List<ZipCode_Log__c> getNonUSLogs() {
        return [
            SELECT Id, ZipCode__c, Country__c, State__c, Place_Name__c, CreatedDate 
            FROM ZipCode_Log__c 
            WITH USER_MODE 
            ORDER BY CreatedDate DESC 
            LIMIT 50
        ];
    }
}