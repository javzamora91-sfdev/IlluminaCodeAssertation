@isTest
public class ZippopotamCalloutMock implements HttpCalloutMock {
    private Integer statusCode;
    private String responseType;

    public ZippopotamCalloutMock(Integer statusCode, String responseType) {
        this.statusCode = statusCode;
        this.responseType = responseType;
    }

    public HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(this.statusCode);
        response.setHeader('Content-Type', 'application/json');

        if (this.statusCode == 200) {
            if (this.responseType == 'US') {
                response.setBody('{' +
                    '"post code": "60137",' +
                    '"country": "United States",' +
                    '"country abbreviation": "US",' +
                    '"places": [{' +
                        '"place name": "Glen Ellyn",' +
                        '"state": "Illinois",' +
                        '"state abbreviation": "IL",' +
                        '"latitude": "41.8661",' +
                        '"longitude": "-88.0648"' +
                    '}]' +
                '}');
            } else if (this.responseType == 'MX') {
                response.setBody('{' +
                    '"post code": "60137",' +
                    '"country": "Mexico",' +
                    '"country abbreviation": "MX",' +
                    '"places": [{' +
                        '"place name": "Leandro Valle",' +
                        '"state": "Michoacan De Ocampo",' +
                        '"state abbreviation": "MIC",' +
                        '"latitude": "19.4167",' +
                        '"longitude": "-102.0500"' +
                    '}]' +
                '}');
            }
        } else if (this.statusCode == 404) {
            response.setBody('{}');
        }

        return response;
    }
}