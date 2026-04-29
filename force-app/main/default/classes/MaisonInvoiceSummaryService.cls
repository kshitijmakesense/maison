public without sharing class MaisonInvoiceSummaryService {

    @AuraEnabled(cacheable=true)
    public static InvoiceSummaryDTO getInvoiceSummary() {

        User u = [
            SELECT ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        if (u.ContactId == null) return new InvoiceSummaryDTO();

        Contact c = [
            SELECT AccountId
            FROM Contact
            WHERE Id = :u.ContactId
            LIMIT 1
        ];
        if (c.AccountId == null) return new InvoiceSummaryDTO();

        List<Xero_Invoice__c> invoices = [
            SELECT Total_Amount__c,
                   Amount_Due__c,
                   Payment_Status__c,
                   Last_Payment_Date__c
            FROM Xero_Invoice__c
            WHERE Account__c = :c.AccountId
        ];

        Integer pendingCount = 0;
        Decimal amountDue = 0;
        Decimal paidThisYear = 0;
        Integer totalCount = invoices.size();
        Integer currentYear = Date.today().year();

        for (Xero_Invoice__c inv : invoices) {

            if (inv.Payment_Status__c != 'Paid') {
                pendingCount++;
                amountDue += inv.Amount_Due__c != null ? inv.Amount_Due__c : 0;
            }

            if (
                inv.Payment_Status__c == 'Paid' &&
                inv.Last_Payment_Date__c != null &&
                inv.Last_Payment_Date__c.year() == currentYear
            ) {
                paidThisYear += inv.Total_Amount__c != null ? inv.Total_Amount__c : 0;
            }
        }

        InvoiceSummaryDTO dto = new InvoiceSummaryDTO();
        dto.pendingInvoices = pendingCount;
        dto.amountDue = amountDue;
        dto.paidThisYear = paidThisYear;
        dto.totalInvoices = totalCount;

        return dto;
    }

    public class InvoiceSummaryDTO {
        @AuraEnabled public Integer pendingInvoices = 0;
        @AuraEnabled public Decimal amountDue = 0;
        @AuraEnabled public Decimal paidThisYear = 0;
        @AuraEnabled public Integer totalInvoices = 0;
    }
}