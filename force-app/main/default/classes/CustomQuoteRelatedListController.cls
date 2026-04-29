public with sharing class CustomQuoteRelatedListController {

    @AuraEnabled(cacheable=true)
    public static List<Quote> getQuotes(Id parentId) {
        return [
            SELECT Id,
                   Name,
                   Quotient_Quote_Number__c,
                   TotalPrice,
                   Total_Price_Including_Tax__c,
                   AccountId,
                   OpportunityId, Status
            FROM Quote
            WHERE AccountId = :parentId
               OR OpportunityId = :parentId
            ORDER BY CreatedDate DESC
        ];
    }
}