public without sharing class MaisonRecentInvoicesService {

    @AuraEnabled(cacheable=true)
    public static List<InvoiceDTO> getRecentInvoices() {

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

        List<Xero_Invoice__c> invoices = [
            SELECT Id,
                   Name,
                   Total_Amount__c,
                   Due_Date__c,
                   Last_Payment_Date__c,
                   Payment_Status__c,
                   Xero_Invoice_Number__c, 
                   Xero_URL__c,  Quote__c, Amount_Due__c,
        Quote__r.Name,  Quote__r.Opportunity.Occasion__c, Payment_URL__c
            FROM Xero_Invoice__c
            WHERE Account__c = :c.AccountId
            ORDER BY CreatedDate DESC
            LIMIT 5
        ];

        List<InvoiceDTO> result = new List<InvoiceDTO>();
        for (Xero_Invoice__c inv : invoices) {
            result.add(new InvoiceDTO(inv));
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
public static InvoiceSummaryDTO getInvoiceSummary() {

    User u = [
        SELECT ContactId
        FROM User
        WHERE Id = :UserInfo.getUserId()
        LIMIT 1
    ];
    if (u.ContactId == null) {
        return new InvoiceSummaryDTO(0, 0);
    }

    Contact c = [
        SELECT AccountId
        FROM Contact
        WHERE Id = :u.ContactId
        LIMIT 1
    ];
    if (c.AccountId == null) {
        return new InvoiceSummaryDTO(0, 0);
    }

    AggregateResult ar = [
        SELECT
            SUM(Amount_Due__c) totalDue,
            COUNT(Id) dueCount
        FROM Xero_Invoice__c
        WHERE Account__c = :c.AccountId
        AND Payment_Status__c != 'Paid'
    ];

    Decimal total = (Decimal) ar.get('totalDue');
    Integer count = (Integer) ar.get('dueCount');

    return new InvoiceSummaryDTO(
        total != null ? total : 0,
        count != null ? count : 0
    );
}

    public class InvoiceSummaryDTO {
    @AuraEnabled public Decimal totalOutstanding;
    @AuraEnabled public Integer dueCount;

    public InvoiceSummaryDTO(Decimal totalOutstanding, Integer dueCount) {
        this.totalOutstanding = totalOutstanding;
        this.dueCount = dueCount;
    }
}


    public class InvoiceDTO {
    @AuraEnabled public Id id;
    @AuraEnabled public String title;
    @AuraEnabled public String invoiceNumber;
    @AuraEnabled public String dateLabel;
    @AuraEnabled public String status;
    @AuraEnabled public Decimal amount;
    @AuraEnabled public Boolean showPay;
    @AuraEnabled public Boolean showPending;   // ✅ NEW
    @AuraEnabled public String xeroUrl;

    public InvoiceDTO(Xero_Invoice__c inv) {
        id = inv.Id;

        title = inv.Quote__r != null &&
                inv.Quote__r.Opportunity != null
                ? inv.Quote__r.Opportunity.Occasion__c
                : null;

        invoiceNumber = inv.Xero_Invoice_Number__c;

        status = inv.Payment_Status__c;   // 🔹 DO NOT CHANGE THIS

        amount = inv.Total_Amount__c;

        xeroUrl = inv.Payment_URL__c;  // 🔹 Use Payment_URL__c (not Xero_URL__c)

        // Date label
        if (inv.Payment_Status__c == 'Paid' && inv.Last_Payment_Date__c != null) {
            dateLabel = 'Paid: ' + inv.Last_Payment_Date__c.format();
        } else {
            dateLabel = 'Due: ' + inv.Due_Date__c.format();
        }

        // 🔹 Clean Payment Button Logic
        showPay = false;
        showPending = false;

        String paymentStatus = inv.Payment_Status__c;
        String paymentUrl = inv.Payment_URL__c;

        if (paymentStatus == 'Paid') {
            // Hide everything
            showPay = false;
            showPending = false;
        }
        else if (!String.isBlank(paymentUrl)) {
            // Payment link exists
            showPay = true;
        }
        else if (String.isBlank(paymentUrl) && paymentStatus == 'Unpaid') {
            // Draft / not approved
            showPending = true;
        }
    }
}

}