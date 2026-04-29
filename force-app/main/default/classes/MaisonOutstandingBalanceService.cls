public without sharing class MaisonOutstandingBalanceService {

    @AuraEnabled(cacheable=true)
    public static OutstandingSummaryDTO getOutstandingSummary() {

        /* ----------------------------------------
         * 1️⃣ Resolve Account from logged-in user
         * ---------------------------------------- */
        User u = [
            SELECT ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        if (u.ContactId == null) {
            return new OutstandingSummaryDTO(0, 0);
        }

        Contact c = [
            SELECT AccountId
            FROM Contact
            WHERE Id = :u.ContactId
            LIMIT 1
        ];
        if (c.AccountId == null) {
            return new OutstandingSummaryDTO(0, 0);
        }

        /* ----------------------------------------
         * 2️⃣ Fetch unpaid / partially paid invoices
         * ---------------------------------------- */
        List<Xero_Invoice__c> invoices = [
            SELECT
                Id,
                Total_Amount__c, Amount_Due__c,
                Payment_Status__c
            FROM Xero_Invoice__c
            WHERE Account__c = :c.AccountId
            AND Payment_Status__c != 'Paid'
        ];

        /* ----------------------------------------
         * 3️⃣ Calculate totals
         * ---------------------------------------- */
        Decimal totalOutstanding = 0;
        Integer invoiceCount = 0;

        for (Xero_Invoice__c inv : invoices) {
            if (inv.Amount_Due__c != null) {
                totalOutstanding += inv.Amount_Due__c;
            }
            invoiceCount++;
        }

        return new OutstandingSummaryDTO(
            totalOutstanding,
            invoiceCount
        );
    }

    /* ======================================================
     * DTO
     * ====================================================== */
    public class OutstandingSummaryDTO {
        @AuraEnabled public Decimal totalOutstanding;
        @AuraEnabled public Integer invoiceCount;

        public OutstandingSummaryDTO(
            Decimal totalOutstanding,
            Integer invoiceCount
        ) {
            this.totalOutstanding = totalOutstanding;
            this.invoiceCount = invoiceCount;
        }
    }
}