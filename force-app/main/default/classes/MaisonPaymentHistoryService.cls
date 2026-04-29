public without sharing class MaisonPaymentHistoryService {

    @AuraEnabled(cacheable=true)
    public static List<PaymentDTO> getPaymentHistory() {

        // Resolve Account
        User u = [
            SELECT ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        if (u.ContactId == null) return new List<PaymentDTO>();

        Contact c = [
            SELECT AccountId
            FROM Contact
            WHERE Id = :u.ContactId
            LIMIT 1
        ];
        if (c.AccountId == null) return new List<PaymentDTO>();

        // Fetch PAID invoices
        List<Xero_Invoice__c> invoices = [
            SELECT
                Id,
                Xero_Invoice_Number__c,
                Total_Amount__c,Amount_Paid__c,
                CreatedDate,
                Quote__r.Name,
                Quote__r.Opportunity.Occasion__c, Last_Payment_Date__c
            FROM Xero_Invoice__c
            WHERE Account__c = :c.AccountId
              AND Payment_Status__c IN ('Paid', 'Partially Paid')
            ORDER BY CreatedDate DESC
        ];

        List<PaymentDTO> result = new List<PaymentDTO>();
        for (Xero_Invoice__c inv : invoices) {
            result.add(new PaymentDTO(inv));
        }

        return result;
    }

    // ---------------------------------------
    // DTO
    // ---------------------------------------
    public class PaymentDTO {
        @AuraEnabled public Date paymentDate;
        @AuraEnabled public String description;
        @AuraEnabled public String invoiceNumber;
        @AuraEnabled public Decimal amount;

        public PaymentDTO(Xero_Invoice__c inv) {
            paymentDate = inv.Last_Payment_Date__c;
            description = inv.Quote__r != null
                ? inv.Quote__r.Opportunity.Occasion__c
                : null;
            invoiceNumber = inv.Xero_Invoice_Number__c;
            amount = inv.Amount_Paid__c;
        }
    }
}