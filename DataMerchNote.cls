/*
*   DataMerch API integration
*   Author: Dan Niyazov
*   5/27/2020
*   All rights reserved
*   Copyright Dan Niyazov 2020
*/
public class DataMerchNote {
    @AuraEnabled public String note;
    @AuraEnabled public String addedBy;
    @AuraEnabled public Datetime createdAt;
    @AuraEnabled public String category;
    
    public void setCreatedDate(String dateString){
        if(!String.isEmpty(dateString) && !dateString.equals('null'))
            createdAt = (Datetime)JSON.deserialize(dateString, Datetime.class);
    }

}