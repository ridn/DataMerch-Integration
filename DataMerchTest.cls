/*
*   DataMerch API integration
*   Author: Dan Niyazov
*   5/27/2020
*   All rights reserved
*   Copyright Dan Niyazov 2020
*/
@isTest
private class DataMerchTest {
  private static String successBody = '[' +
                '{' +
                  '"merchant": {' +
                    '"fein": "01-2345678",' +
                    '"legal_name": "ACME Company",' +
                    '"dba": "ACME",' +
                    '"address": "123 First Ave. S.",' +
                    '"street1": "",' +
                    '"street2": "",' +
                    '"city": "Los Angeles",' +
                    '"state": "CA",' +
                    '"business_phone": "123-456-7890",' +
                    '"business_startdate": "1/1/1985",' +
                    '"industry": "Combustables",' +
                    '"notes": [' +
                      '{' +
                        '"note": {' +
                          '"category": "Slow Pay",' +
                          '"note": "Merchant is a slow pay and/or default account.",' +
                          '"created_at": "2015-09-01T04:21.41Z",' +
                          '"added_by": "XYZ Funder"' +
                        '}' +
                      '}' +
                    ']' +
                  '}' +
                '}' +
              ']';
    
     @testSetup static void setup() {

        String[] feins = new String[]{'','invalid','99-9999999','01-2345678'};
        List<Account> accounts = new List<Account>();
        for(String fein : feins){
            // Create common test accounts
            Account acc = new Account(
                McaApp__Federal_Tax_ID_No__c = fein,
                Name='TestAcct' + feins.indexOf(fein),
                Phone = '1234',
                FAX = '123',
                Billingstreet = 'test'
            );
            accounts.add(acc);
            
        }
       insert accounts;
       System.debug(accounts.toString());

    }
  @isTest static void testDateMerchNote() {
    DataMerchNote note = new DataMerchNote();
    note.note = 'content';
    note.addedBy = 'ABC FUNDER';
    note.category = 'Slow Payer';
    Datetime now = datetime.now();
    note.setCreatedDate(json.serialize(now));
    System.assertEquals(note.createdAt,now);
    
    
  }
  @isTest static void testNoRecordID(){
    List<DataMerch.Merchant> result = DataMerch.getMerchantByFEIN(new List<String>());
    List<DataMerch.Merchant> expected = new List<DataMerch.Merchant>();

    DataMerch.Merchant merch = new DataMerch.Merchant();
    merch.setError('NO ACCOUNT FOUND');
    expected.add(merch);
    System.assert(result.equals(expected));
    
  }
  @isTest static void testNoAccountFound(){
    List<String> testList = new List<String>{'aaaaaaaaaaaaaaa'};
    List<DataMerch.Merchant> result = DataMerch.getMerchantByFEIN(testList);
    List<DataMerch.Merchant> expected = new List<DataMerch.Merchant>();

    DataMerch.Merchant merch = new DataMerch.Merchant();
    merch.setError('NO ACCOUNT FOUND');
    expected.add(merch);
    System.assert(result.equals(expected));
    
  }
  @isTest static void testNoFEINFound(){
        Account acc = [SELECT Id FROM Account WHERE Name='TestAcct0' LIMIT 1];

       List<String> testList = new List<String>{acc.id};
       List<DataMerch.Merchant> result = DataMerch.getMerchantByFEIN(testList);
       List<DataMerch.Merchant> expected = new List<DataMerch.Merchant>();
   
       DataMerch.Merchant merch = new DataMerch.Merchant();
       merch.setError('NO FEIN FOUND');
       expected.add(merch);
       System.assert(result.equals(expected));

    
  }
  @isTest static void testInvalidFEIN(){
    //DUE TO VALIDATION RULES THIS SHOULD NOT OCCUR
    
       //impossible to test, cannot save invalid format
        Account acc = [SELECT Id FROM Account WHERE Name='TestAcct1' LIMIT 1];


       List<String> testList = new List<String>{acc.id};
       //Test.setMock(HttpCalloutMock.class, new DataMerchMockCallout(204,'','',(Map<String,String>)null));
       Test.startTest();
       List<DataMerch.Merchant> result = DataMerch.getMerchantByFEIN(testList);
       List<DataMerch.Merchant> expected = new List<DataMerch.Merchant>();
   
       DataMerch.Merchant merch = new DataMerch.Merchant();
       merch.setError('INVALID FEIN FORMAT');
       expected.add(merch);
       //System.debug(expected + '\n' + result);
       System.assert(result.equals(expected));
       Test.stopTest();

    
  }
  @isTest static void testNoMerchantFound(){

        Account acc = [SELECT Id FROM Account WHERE Name='TestAcct2' LIMIT 1];
       List<String> testList = new List<String>{acc.id};

       //while a 204 is expected, the result is reponse 200 with an empty array body
       Test.setMock(HttpCalloutMock.class, new DataMerchMockCallout(200,'','[]',new Map<String, String>{'Content-Type' => 'application/json'}));
       //Test.setMock(HttpCalloutMock.class, new DataMerchMockCallout(204,'','',null);
       Test.startTest();
       List<DataMerch.Merchant> result = DataMerch.getMerchantByFEIN(testList);
       List<DataMerch.Merchant> expected = new List<DataMerch.Merchant>();
   
       DataMerch.Merchant merch = new DataMerch.Merchant();
       merch.setError('NO MERCHANT FOUND');
       expected.add(merch);
       System.assert(result.equals(expected));
       Test.stopTest();

    
  }
  @isTest static void testSuccess(){
        Account acc = [SELECT Id, McaApp__Federal_Tax_ID_No__c FROM Account WHERE Name='TestAcct3' LIMIT 1];

       List<String> testList = new List<String>{acc.id};
       Test.setMock(HttpCalloutMock.class, new DataMerchMockCallout(200,'TEST',successBody,new Map<String, String>{'Content-Type' => 'application/json'}));
       Test.startTest();
       List<DataMerch.Merchant> result = DataMerch.getMerchantByFEIN(testList);
       Test.stopTest();
       List<DataMerch.Merchant> expected = new List<DataMerch.Merchant>();
   
       DataMerch.Merchant merch = new DataMerch.Merchant();
       merch.taxID = acc.McaApp__Federal_Tax_ID_No__c;
       expected.add(merch);
       System.assert(result.equals(expected));
  }

}