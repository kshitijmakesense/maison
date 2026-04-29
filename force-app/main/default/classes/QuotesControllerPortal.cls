public with sharing class QuotesControllerPortal {
    
    @AuraEnabled(cacheable=true)
    public static QuoteWrapper getFullQuoteDetails(Id quoteId) {

        Quote q = [
            SELECT Id, Name, Quotient_Quote_Number__c, Status,
                   Sent_Date__c, ExpirationDate, Active__c,
                   TotalPrice, Total_Price_Including_Tax__c,
                   Opportunity.Name, Contact.Name,
                   Quotient_Quote_URL__c
            FROM Quote
            WHERE Id = :quoteId
        ];

        List<QuoteLineItem> qlis = [
            SELECT Id, Quantity, UnitPrice, TotalPrice, Tax_Rate__c, Tax_Amount__c,
                   PricebookEntry.Product2.Name
            FROM QuoteLineItem
            WHERE QuoteId = :quoteId
        ];

        return new QuoteWrapper(q, qlis);
    }

    public class QuoteWrapper {
        @AuraEnabled public Quote quote;
        @AuraEnabled public List<QuoteLineItem> lineItems;

        public QuoteWrapper(Quote q, List<QuoteLineItem> li) {
            quote = q;
            lineItems = li;
        }
    }
}