public without sharing class MaisonRecentQuotesService {

    @AuraEnabled(cacheable=true)
    public static List<QuoteDTO> getRecentQuotes() {

        User u = [
            SELECT ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        if (u.ContactId == null) return new List<QuoteDTO>();

        Contact c = [
            SELECT AccountId
            FROM Contact
            WHERE Id = :u.ContactId
            LIMIT 1
        ];
        if (c.AccountId == null) return new List<QuoteDTO>();

        List<Quote> quotes = [
            SELECT Id, Name, Status,Total_Price_Including_Tax__c, ExpirationDate, GrandTotal, Opportunity.Occasion__c, Quotient_Quote_Number__c, Quotient_Quote_URL__c, 
                   (
                       SELECT Payment_Status__c, Xero_URL__c, Payment_URL__c
                       FROM Xero_Invoices__r
                       ORDER BY CreatedDate DESC
                       LIMIT 1
                   )
            FROM Quote
            WHERE AccountId = :c.AccountId
            ORDER BY CreatedDate DESC
            LIMIT 5
        ];

        List<QuoteDTO> result = new List<QuoteDTO>();
        for (Quote q : quotes) {
            result.add(new QuoteDTO(q));
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
public static Integer getActiveQuoteCount() {

    User u = [
        SELECT ContactId
        FROM User
        WHERE Id = :UserInfo.getUserId()
        LIMIT 1
    ];
    if (u.ContactId == null) return 0;

    Contact c = [
        SELECT AccountId
        FROM Contact
        WHERE Id = :u.ContactId
        LIMIT 1
    ];
    if (c.AccountId == null) return 0;

    return [
        SELECT COUNT()
        FROM Quote
        WHERE AccountId = :c.AccountId
          AND Status IN ('Sent', 'Viewed')
    ];
}


    public class QuoteDTO {
    @AuraEnabled public Id id;
    @AuraEnabled public String name;
    @AuraEnabled public String status;
    @AuraEnabled public Date validUntil;
    @AuraEnabled public Decimal amount;

    // ✅ NEW FIELDS
    @AuraEnabled public String occasion;
    @AuraEnabled public String quoteNumber;

     // ✅ NEW
    @AuraEnabled public String quoteUrl;
     // 🔑 CONTROL FLAG
    @AuraEnabled public Boolean showPay;
    @AuraEnabled public String xeroUrl;
    @AuraEnabled public Boolean showPending;

    public QuoteDTO(Quote q) {
        id = q.Id;
        name = q.Name;
        status = q.Status;
        validUntil = q.ExpirationDate;
        amount = q.Total_Price_Including_Tax__c;
       //   showPay = false;
      
        // ✅ SAFE NULL HANDLING
        occasion = q.Opportunity != null ? q.Opportunity.Occasion__c : null;
        quoteNumber = q.Quotient_Quote_Number__c;
         // ✅ MAP URL
        quoteUrl = q.Quotient_Quote_URL__c;
        /* String paymentStatus;
            if (q.Xero_Invoices__r != null && !q.Xero_Invoices__r.isEmpty()) {
                paymentStatus = q.Xero_Invoices__r[0].Payment_Status__c;
            }

            // ✅ FINAL BUSINESS RULE
            showPay = (q.Status == 'Accepted' && paymentStatus != 'Paid');*/
            /* showPay = false;
        xeroUrl = null;

        if (
            q.Status == 'Accepted' &&
            q.Xero_Invoices__r != null &&
            !q.Xero_Invoices__r.isEmpty()
        ) {
            Xero_Invoice__c inv = q.Xero_Invoices__r[0];

            if (inv.Payment_Status__c != 'Paid') {
                showPay = true;
                xeroUrl = inv.Payment_URL__c;
            }
        }*/
        showPay = false;
showPending = false;
xeroUrl = null;

if (
    q.Status == 'Accepted' &&
    q.Xero_Invoices__r != null &&
    !q.Xero_Invoices__r.isEmpty()
) {
    Xero_Invoice__c inv = q.Xero_Invoices__r[0];

    String paymentStatus = inv.Payment_Status__c;
    String paymentUrl = inv.Payment_URL__c;

    // 🔹 If invoice is Paid → Hide Pay
    if (paymentStatus == 'Paid') {
        showPay = false;
        showPending = false;
    }

    // 🔹 If payment link exists and not paid → Show Pay
    else if (!String.isBlank(paymentUrl)) {
        showPay = true;
         xeroUrl = paymentUrl;
    }

    // 🔹 If no link and unpaid → Show Pending Approval
    else{
        showPending = true;
    }
}

        
    }
}

}