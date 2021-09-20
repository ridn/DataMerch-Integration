/*
*   DataMerch API integration
*   Author: Dan Niyazov
*   5/27/2020
*   All rights reserved
*   Copyright Dan Niyazov 2020
*/
@isTest public class DataMerchMockCallout implements HttpCalloutMock {
      protected Integer code;
      protected String status;
      protected String bodyAsString;
      protected Map<String, String> responseHeaders;
  public DataMerchMockCallout(Integer code, String status, String body, Map<String, String> responseHeaders) {
          this.code = code;
          this.status = status;
          this.bodyAsString = body;
          this.responseHeaders = responseHeaders;

          cmbla__DataMerchAPIDetail__c setting = new cmbla__DataMerchAPIDetail__c();
          setting.Name = 'Data Merch Detail';
          setting.cmbla__UserName__c = 'USERNAME';
          setting.cmbla__Password__c = 'PASSWORD';
          insert setting;
      }
  public HTTPResponse respond(HTTPRequest req) {
      //System.assertEquals('http://example.com/example/test', req.getEndpoint());
     System.assertEquals('GET', req.getMethod());
     HttpResponse res = new HttpResponse();
      if (responseHeaders != null) {
          for (String key : responseHeaders.keySet()) {
            res.setHeader(key, responseHeaders.get(key));
         }
      }
      res.setBody(bodyAsString);
      res.setStatusCode(code);
      res.setStatus(status);
      return res;
  }
}