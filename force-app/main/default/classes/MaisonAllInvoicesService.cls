public without sharing class MaisonAllInvoicesService {

    @AuraEnabled(cacheable=true)
    public static List<InvoiceDTO> getAllInvoices() {

        /* ----------------------------------------
         * 1️⃣ Resolve Account from logged-in user
         * ---------------------------------------- */
        User u = [
            SELECT ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        if (u.ContactId == null) return new List<InvoiceDTO>();

        Contact c = [
            SELECT AccountId
            FROM Contact
            WHERE Id = :u.ContactId
            LIMIT 1
        ];
        if (c.AccountId == null) return new List<InvoiceDTO>();

        /* ----------------------------------------
         * 2️⃣ Fetch invoices
         * ---------------------------------------- */
        List<Xero_Invoice__c> invoices = [
            SELECT
                Id,
                Xero_Invoice_Number__c,
                Payment_Status__c,
                CreatedDate,
                Due_Date__c,
                Total_Amount__c,
                Xero_URL__c, Quote__c,  Quote__r.Name,  Quote__r.Opportunity.Occasion__c, Payment_URL__c
            FROM Xero_Invoice__c
            WHERE Account__c = :c.AccountId
            ORDER BY CreatedDate DESC
        ];

        if (invoices.isEmpty()) return new List<InvoiceDTO>();

        /* ----------------------------------------
         * 3️⃣ Fetch related bookings separately
         * ---------------------------------------- */
        Set<Id> invoiceIds = new Set<Id>();
        for (Xero_Invoice__c inv : invoices) {
            invoiceIds.add(inv.Id);
        }

        Map<Id, Order> bookingByInvoice = new Map<Id, Order>();

        for (Order b : [
            SELECT
                Id,
                OrderNumber,
                Xero_Invoice__c,
                Opportunity.Occasion__c
            FROM Order
            WHERE Xero_Invoice__c IN :invoiceIds
            ORDER BY CreatedDate DESC
        ]) {
            // Keep the most recent booking per invoice
            if (!bookingByInvoice.containsKey(b.Xero_Invoice__c)) {
                bookingByInvoice.put(b.Xero_Invoice__c, b);
            }
        }

        /* ----------------------------------------
         * 4️⃣ Build DTOs
         * ---------------------------------------- */
        List<InvoiceDTO> result = new List<InvoiceDTO>();
        for (Xero_Invoice__c inv : invoices) {
            result.add(new InvoiceDTO(inv, bookingByInvoice.get(inv.Id)));
        }

        return result;
    }

    /* ======================================================
     * DTO
     * ====================================================== */
    public class InvoiceDTO {

        @AuraEnabled public Id id;
        @AuraEnabled public String invoiceNumber;
        @AuraEnabled public String eventTitle;
        @AuraEnabled public String relatedBooking;
        @AuraEnabled public Datetime issueDate;
        @AuraEnabled public Date dueDate;
        @AuraEnabled public String status;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public Boolean showPay;
        @AuraEnabled public String xeroUrl;
        @AuraEnabled public Boolean showPending; 

        public InvoiceDTO(Xero_Invoice__c inv, Order booking) {

    id = inv.Id;
    invoiceNumber = inv.Xero_Invoice_Number__c;
    issueDate = inv.CreatedDate;
    dueDate = inv.Due_Date__c;
    status = inv.Payment_Status__c;
    amount = inv.Total_Amount__c;

    if (booking != null) {
        relatedBooking = booking.OrderNumber;
    }

    eventTitle = inv.Quote__r != null &&
                 inv.Quote__r.Opportunity != null
        ? inv.Quote__r.Opportunity.Occasion__c
        : null;

    showPay = false;
    showPending = false;
    xeroUrl = inv.Xero_URL__c;

    String paymentStatus = inv.Payment_Status__c;
    String paymentUrl = inv.Payment_URL__c;

    // 🔹 If Paid → no Pay button
    if (paymentStatus == 'Paid') {
        showPay = false;
        xeroUrl = paymentUrl;
    }

    // 🔹 If payment link exists → allow Pay
    else if (!String.isBlank(paymentUrl)) {
        showPay = true;
        xeroUrl = paymentUrl;
    }

    // 🔹 Draft (Unpaid + no link)
    else if (String.isBlank(paymentUrl) && paymentStatus == 'Unpaid') {
        showPending = true;
    }
}

    }
}