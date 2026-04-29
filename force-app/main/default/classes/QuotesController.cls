public with sharing class QuotesController {

    @AuraEnabled(cacheable=true)
    public static List<QuoteWrapper> getQuotes(Id accountId) {
        List<QuoteWrapper> results = new List<QuoteWrapper>();

        List<Quote> quotes = [
            SELECT Id, Name, QuoteNumber, Status, TotalPrice, CreatedDate,
                   ExpirationDate, Opportunity.Event_Date__c,
                   (SELECT Id, Product2.Name FROM QuoteLineItems)
            FROM Quote
            WHERE AccountId = :accountId
            ORDER BY CreatedDate DESC
        ];

        for (Quote q : quotes) {
            QuoteWrapper wrap = new QuoteWrapper();
            wrap.quoteId = q.Id;
            wrap.title = q.Name;
            wrap.quoteNumber = q.QuoteNumber;
            wrap.status = q.Status;
            wrap.totalInvestment = q.TotalPrice;
            wrap.createdDate = q.CreatedDate;
            wrap.eventDate = (q.Opportunity != null) ? q.Opportunity.Event_Date__c : null;

            // Get services from line items
            List<String> services = new List<String>();
            for (QuoteLineItem li : q.QuoteLineItems) {
                services.add(li.Product2.Name);
            }
            wrap.services = String.join(services, ', ');

            results.add(wrap);
        }

        return results;
    }

    public class QuoteWrapper {
        @AuraEnabled public Id quoteId;
        @AuraEnabled public String title;
        @AuraEnabled public String quoteNumber;
        @AuraEnabled public String status;
        @AuraEnabled public Decimal totalInvestment;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public Date eventDate;
        @AuraEnabled public String services;
    }
}