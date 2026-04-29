public with sharing class QuoteInvoiceController {

    @AuraEnabled(cacheable=true)
    public static List<Xero_Invoice__c> getInvoices(Id quoteId) {

        if (quoteId == null) {
            return new List<Xero_Invoice__c>();
        }

        // Fetch invoices directly related to the Quote
        return [
            SELECT Id,
                   Name,
                   Xero_Invoice_Number__c,
                   Payment_Status__c,
                   Total_Amount__c,
                   Invoice_Date__c,
                   Quote__c
            FROM Xero_Invoice__c
            WHERE Quote__c = :quoteId
            ORDER BY Invoice_Date__c DESC
        ];
    }
}