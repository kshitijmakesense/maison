public with sharing class InvoiceDetailController {

    @AuraEnabled(cacheable=true)
    public static Xero_Invoice__c getInvoice(Id invoiceId) {
        return [
            SELECT Id,
                   Name,
                   Xero_Invoice_Number__c,
                   Account__c,
                   Account__r.Name,
                   Quote__c,
                   Quote__r.Name,
                   Event_Title__c,
                   Xero_URL__c,
                   Total_Amount__c,
                   Total_Tax_amount__c,
                   Amount_Due__c,
                   Amount_Paid__c,
                   Payment_Status__c,
                   Last_Payment_Date__c,
                   Order_Created__c
            FROM Xero_Invoice__c
            WHERE Id = :invoiceId
            LIMIT 1
        ];
    }
}