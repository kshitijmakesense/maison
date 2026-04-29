public with sharing class EnquiryInvoiceController {

    @AuraEnabled(cacheable=true)
    public static List<Xero_Invoice__c> getInvoices(Id enquiryId) {

        // 1️⃣ Get all standard Quotes related to the Opportunity (Enquiry)
        List<Quote> quotes = [
            SELECT Id
            FROM Quote
            WHERE OpportunityId = :enquiryId
        ];

        if (quotes.isEmpty()) {
            return new List<Xero_Invoice__c>();
        }

        // 2️⃣ Get all Invoices related to those Quotes
        return [
            SELECT Id, Name, Xero_Invoice_Number__c, Payment_Status__c, Total_Amount__c, Invoice_Date__c, Quote__c
            FROM Xero_Invoice__c
            WHERE Quote__c IN :quotes
            ORDER BY Invoice_Date__c DESC
        ];
    }
}