public with sharing class InvoiceListController {

    @AuraEnabled(cacheable=true)
    public static List<InvoiceWrapper> getInvoices(Id accountId) {

        List<Xero_Invoice__c> invoices = [
            SELECT Id,
                   Name,
                   Xero_Invoice_Number__c,
                   Event_Title__c,
                   Invoice_Date__c,
                   Due_Date__c,
                   Total_Amount__c,
                   Payment_Status__c,
                   Xero_URL__c,
                   Quote__c
            FROM Xero_Invoice__c
            WHERE Account__c = :accountId
            ORDER BY Invoice_Date__c DESC
        ];

        if (invoices.isEmpty()) return new List<InvoiceWrapper>();

        // Get Quote IDs
        Set<Id> quoteIds = new Set<Id>();
        for (Xero_Invoice__c inv : invoices) {
            if (inv.Quote__c != null) quoteIds.add(inv.Quote__c);
        }

        // Fetch Quote line items
        Map<Id, List<QuoteLineItem>> qliMap = new Map<Id, List<QuoteLineItem>>();
        for (QuoteLineItem qli : [
            SELECT Id, Quantity, Description, QuoteId, Product2.Name
            FROM QuoteLineItem
            WHERE QuoteId IN :quoteIds
        ]) {
            if (!qliMap.containsKey(qli.QuoteId))
                qliMap.put(qli.QuoteId, new List<QuoteLineItem>());
            qliMap.get(qli.QuoteId).add(qli);
        }

        // Build wrappers
        List<InvoiceWrapper> results = new List<InvoiceWrapper>();
        for (Xero_Invoice__c inv : invoices) {
            List<String> serviceNames = new List<String>();

            if (qliMap.containsKey(inv.Quote__c)) {
                for (QuoteLineItem item : qliMap.get(inv.Quote__c)) {
                    String label = item.Product2.Name;
                   if (item.Quantity != null && item.Quantity > 1)
    label += ' (' + String.valueOf(item.Quantity.intValue()) + ')';

                    serviceNames.add(label);
                }
            }

            results.add(new InvoiceWrapper(inv, String.join(serviceNames, ', ')));
        }

        return results;
    }

 
    public class InvoiceWrapper {
        @AuraEnabled public Xero_Invoice__c invoice { get; set; }
        @AuraEnabled public String services { get; set; }

        public InvoiceWrapper(Xero_Invoice__c inv, String svc) {
            invoice = inv;
            services = svc;
        }
    }
}