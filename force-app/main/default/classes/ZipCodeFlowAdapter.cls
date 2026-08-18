public with sharing class ZipCodeFlowAdapter {
public class FlowInput {
        @InvocableVariable(required=true label='Country Code')
        public String countryCode;

        @InvocableVariable(required=true label='Zip Code')
        public String zipCode;
    }

    public class FlowOutput {
        @InvocableVariable(label='Is US Zip Code')
        public Boolean isUS;

        @InvocableVariable(label='Country Name')
        public String country;

        @InvocableVariable(label='State Name')
        public String state;

        @InvocableVariable(label='Place Name')
        public String placeName;

        @InvocableVariable(label='Zip Code')
        public String zipCode;
    }

    @InvocableMethod(label='Fetch Zip Code Details' description='Queries Zippopotam API and logs non-US requests.')
    public static List<FlowOutput> fetchZipDetails(List<FlowInput> inputs) {
        List<FlowOutput> outputs = new List<FlowOutput>();

        for (FlowInput input : inputs) {
            ZipCodeController.ZipCodeWrapper res = ZipCodeController.getZipCodeDetails(input.countryCode, input.zipCode);
            
            FlowOutput out = new FlowOutput();
            out.isUS = 'US'.equalsIgnoreCase(res.countryAbbreviation);
            out.country = res.country;
            out.zipCode = res.postCode;

            if (res.places != null && !res.places.isEmpty()) {
                out.state = res.places[0].state;
                
                List<String> names = new List<String>();
                for (ZipCodeController.PlaceWrapper p : res.places) {
                    if (String.isNotBlank(p.placeName)) {
                        names.add(p.placeName);
                    }
                }
                out.placeName = String.join(names, ', ');
            }

            outputs.add(out);
        }

        return outputs;
    }
}