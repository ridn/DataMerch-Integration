/*
*   DataMerch API integration
*   Author: Dan Niyazov
*   5/27/2020
*   All rights reserved
*   Copyright Dan Niyazov 2020
*/
public Class DataMerch {
    @InvocableVariable public String id;
    @InvocableMethod(label='Lookup Merchant on DataMerch')
    public static List<Merchant> getMerchantByFEIN(List<String> merchantAccounts){
        List<Merchant> merchantList = new List<Merchant>();
        Merchant merchant = new Merchant();
        List<Account> accountList = [SELECT id, McaApp__Federal_Tax_ID_No__c from Account WHERE Id in:merchantAccounts];
          for(Account acc : accountList){
            if(acc != null){
                //validate FEIN
                if(!String.isBlank(acc.McaApp__Federal_Tax_ID_No__c)){
                    Pattern feinPattern = Pattern.compile('^[0-9]{2}-[0-9]{7}$');
                    Boolean validFEINFormat = feinPattern.matcher(acc.McaApp__Federal_Tax_ID_No__c).matches();
                    //is a XX-XXXXXXX valid FEIN format
                    if(validFEINFormat) {
                        String fein = acc.McaApp__Federal_Tax_ID_No__c.substring(3);
                        Http http = new Http();
                        cmbla__DataMerchAPIDetail__c dm = cmbla__DataMerchAPIDetail__c.getValues('Data Merch Detail');
                        HttpRequest request = new HttpRequest();
                        request.setEndpoint('callout:DataMerch/api/v1/merchants/' + fein);
                        //request.setEndpoint('https://api.datamerch.com/api/v1/merchants/' + fein);
                        //request.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueof(dm.cmbla__UserName__c + ':'+dm.cmbla__Password__c)));
                        request.setMethod('GET');
                        HttpResponse response = http.send(request);
                        switch on response.getStatusCode() {

                          when 200 {
                              if(String.isEmpty(response.getBody()) || response.getBody().length() <= 2){
                                merchant.setError('NO MERCHANT FOUND');
                                
                              }else{
                                  Map<String,Object> merchantData = (Map<String,Object>)((List<Object>)JSON.deserializeUntyped(response.getBody()))[0];
                                  merchantData = (Map<String,Object>)merchantData.get('merchant');
                                  merchant.taxID = (String)merchantData.get('fein');
                                  merchant.legalName = (String)merchantData.get('legal_name');
                                  merchant.dba = (String)merchantData.get('dba');
                                  merchant.address = (String)merchantData.get('address');
                                  merchant.street = (String)merchantData.get('street1') + '\n' + merchantData.get('street2');
                                  merchant.city = (String)merchantData.get('city');
                                  merchant.state = (String)merchantData.get('state');
                                  merchant.phoneNumber = (String)merchantData.get('business_phone');
                                  merchant.industry = (String)merchantData.get('industry');
                                  merchant.setDateBusinessEstablished((String)merchantData.get('business_startdate'));

                                  List<Object>notesList = (List<Object>)merchantData.get('notes');
                                  Object currentNote;
                                  for(Object n : notesList){
                                      DataMerchNote note = new DataMerchNote();

                                      currentNote = ((Map<String,Object>)n).get('note');
                                      note.note = (String)((Map<String,Object>)currentNote).get('note');
                                      note.addedBy = (String)((Map<String,Object>)currentNote).get('added_by');
                                      note.category = (String)((Map<String,Object>)currentNote).get('category');
                                      note.setCreatedDate('"' + ((Map<String,Object>)currentNote).get('created_at') + '"');
                                      merchant.notes.add(note);
                                  }
                              }
                            }
                              when 204{
                                //NO CONTENT RETURNED
                                merchant.setError('NO DATA FOUND');
                              }
                              when 400 {
                                //BAD REQUEST/INVALID SYNTAX
                                merchant.setError('INVALID REQUEST');
                              }
                              when 401 {
                                merchant.setError('UNAUTHORIZED REQUEST');
                              }
                              when else {
                                merchant.setError('Error ' + response.getStatusCode() + ':' + response.getStatus());
                              }
                          } 
                    }else{
                        //invalid FEIN
                        //System.debug('INVALID FEIN FORMAT');
                        merchant.setError('INVALID FEIN FORMAT');
                    }
                }else{
                    //no FEIN exists
                    //System.debug('NO FEIN');
                    merchant.setError('NO FEIN FOUND');
                }
            }else{
                //no Account found
                //System.debug('NO ACCOUNT');
                merchant.setError('NO ACCOUNT FOUND');
            }
        }
        if(accountList.size() == 0) {
          merchant.setError('NO ACCOUNT FOUND');
        }
        merchantList.add(merchant);
        return merchantList;
    }

      
        public class Merchant{

            @InvocableVariable public String taxID;
            @InvocableVariable public String legalName;
            @InvocableVariable public String dba;
            @InvocableVariable public String address;
            @InvocableVariable public String street;
            @InvocableVariable public String city;
            @InvocableVariable public String state;
            @InvocableVariable public String phoneNumber;
            @InvocableVariable public String industry;
            @InvocableVariable public Datetime dateEstablished;
            @InvocableVariable public List<DataMerchNote> notes;
            @InvocableVariable public Boolean hasError = false;
            @InvocableVariable public String errorText = '';
            
            public Merchant() {
                notes = new List<DataMerchNote>();
            }
            public override String toString() {
                return 'FEIN: ' + taxID + '\nLegal Name: ' + legalName + '\nDBA: ' + dba + '\nHas Error: ' + hasError + '\nError: ' + errorText;
            }
            public void setDateBusinessEstablished(String dateString){
                if(!String.isEmpty(dateString) && !dateString.equals('null'))
                    dateEstablished = (Datetime)JSON.deserialize(dateString, Datetime.class);
            }
            public void setError(String text){
                hasError = true;
                errorText = text;
                
            }
            public Boolean equals(Object obj){
              Boolean dataCheck = (String.isEmpty(taxID) ? String.isEmpty(((Merchant)obj).taxID) : taxID.equals(((Merchant)obj).taxID));
              return (hasError == ((Merchant)obj).hasError && errorText.equals(((Merchant)obj).errorText) && dataCheck);
            }
            

          }
}