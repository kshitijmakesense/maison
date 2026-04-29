public without sharing class MaisonOutstandingPaymentsService {

    @AuraEnabled(cacheable=true)
    public static List<OutstandingPaymentDTO> getOutstandingPayments() {

        // 1️⃣ Resolve Account
        User u = [
            SELECT ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        if (u.ContactId == null) return new List<OutstandingPaymentDTO>();

        Contact c = [
            SELECT AccountId
            FROM Contact
            WHERE Id = :u.ContactId
            LIMIT 1
        ];
        if (c.AccountId == null) return new List<OutstandingPaymentDTO>();

        // 2️⃣ Fetch outstanding invoices
        List<Xero_Invoice__c> invoices = [
            SELECT
                Id,
                Xero_Invoice_Number__c,
                Due_Date__c, Amount_Due__c,
                Total_Amount__c,
                Payment_Status__c,
                Xero_URL__c,
               Quote__c,  Quote__r.Name,  Quote__r.Opportunity.Occasion__c, Payment_URL__c
            FROM Xero_Invoice__c
            WHERE Account__c = :c.AccountId
            AND Payment_Status__c != 'Paid'
            ORDER BY Due_Date__c ASC
        ];

        List<OutstandingPaymentDTO> result = new List<OutstandingPaymentDTO>();
        for (Xero_Invoice__c inv : invoices) {
            result.add(new OutstandingPaymentDTO(inv));
        }
        return result;
    }

    // ======================================================
    // DTO
    // ======================================================
    public class OutstandingPaymentDTO {

        @AuraEnabled public String description;
        @AuraEnabled public String invoiceNumber;
        @AuraEnabled public Date dueDate;
        @AuraEnabled public Boolean isOnCompletion;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public String payUrl;
        @AuraEnabled public Boolean showPay;
@AuraEnabled public Boolean showPending;


        public OutstandingPaymentDTO(Xero_Invoice__c inv) {

    description = inv.Quote__r != null &&
                  inv.Quote__r.Opportunity != null
        ? inv.Quote__r.Opportunity.Occasion__c
        : 'Invoice';

    invoiceNumber = inv.Xero_Invoice_Number__c;

    dueDate = inv.Due_Date__c;
    isOnCompletion = inv.Due_Date__c == null;

    amount = inv.Amount_Due__c;

    showPay = false;
    showPending = false;
    payUrl = null;

    String paymentStatus = inv.Payment_Status__c;
    String paymentUrl = inv.Payment_URL__c;

    // 🔹 If payment link exists → allow Pay
    if (!String.isBlank(paymentUrl)) {
        showPay = true;
        payUrl = paymentUrl;
    }
    // 🔹 No link + unpaid → pending approval
    else if (String.isBlank(paymentUrl) && paymentStatus == 'Unpaid') {
        showPending = true;
    }
}

    }
}