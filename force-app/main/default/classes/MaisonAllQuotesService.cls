public without sharing class MaisonAllQuotesService {

    public class QuotePageResult {
        @AuraEnabled public List<QuoteDTO> records;
        @AuraEnabled public Integer totalCount;

        public QuotePageResult(List<QuoteDTO> records, Integer totalCount) {
            this.records = records;
            this.totalCount = totalCount;
        }
    }

    @AuraEnabled(cacheable=true)
    public static QuotePageResult getAllQuotes(Integer pageSize, Integer pageNumber) {

        if (pageSize == null || pageSize <= 0) pageSize = 10;
        if (pageNumber == null || pageNumber < 1) pageNumber = 1;

        Integer offsetVal = (pageNumber - 1) * pageSize;

        User u = [
            SELECT ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        if (u.ContactId == null)
            return new QuotePageResult(new List<QuoteDTO>(), 0);

        Contact c = [
            SELECT AccountId
            FROM Contact
            WHERE Id = :u.ContactId
            LIMIT 1
        ];
        if (c.AccountId == null)
            return new QuotePageResult(new List<QuoteDTO>(), 0);

        Integer totalCount = [
            SELECT COUNT()
            FROM Quote
            WHERE AccountId = :c.AccountId
        ];

        List<Quote> quotes = [
            SELECT Id,
                   Status,
                   ExpirationDate,
                   Total_Price_Including_Tax__c,
                   Opportunity.Occasion__c,
                   Opportunity.Venue_Address__c,
                   Quotient_Quote_Number__c,
                   Quotient_Quote_URL__c,
                   (
                       SELECT Payment_Status__c, Xero_URL__c, Payment_URL__c
                       FROM Xero_Invoices__r
                       ORDER BY CreatedDate DESC
                       LIMIT 1
                   )
            FROM Quote
            WHERE AccountId = :c.AccountId
            ORDER BY CreatedDate DESC
            LIMIT :pageSize
            OFFSET :offsetVal
        ];

        List<QuoteDTO> result = new List<QuoteDTO>();
        for (Quote q : quotes) {
            result.add(new QuoteDTO(q));
        }

        return new QuotePageResult(result, totalCount);
    }

    @AuraEnabled(cacheable=true)
public static Integer getTotalQuoteCount() {

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
    ];
}


    /* ================= DTO ================= */
   public class QuoteDTO {
    @AuraEnabled public Id id;
    @AuraEnabled public String title;
    @AuraEnabled public String venue;
    @AuraEnabled public String validUntil;
    @AuraEnabled public String status;
    @AuraEnabled public Decimal amount;
    @AuraEnabled public String quoteNumber;
    @AuraEnabled public String quoteUrl;

    @AuraEnabled public Boolean showPay;
    @AuraEnabled public Boolean showPending;   // ✅ NEW
    @AuraEnabled public String xeroUrl;
    @AuraEnabled public Boolean showPaid;

    public QuoteDTO(Quote q) {
        id = q.Id;
        title = q.Opportunity != null ? q.Opportunity.Occasion__c : null;
        venue = q.Opportunity != null ? q.Opportunity.Venue_Address__c : null;
        status = q.Status;
        amount = q.Total_Price_Including_Tax__c;
        quoteNumber = q.Quotient_Quote_Number__c;
        quoteUrl = q.Quotient_Quote_URL__c;

        if (q.ExpirationDate != null) {
            DateTime dt = DateTime.newInstance(
                q.ExpirationDate,
                Time.newInstance(0, 0, 0, 0)
            );
            validUntil = dt.format('MMM d, yyyy');
        }
showPay = false;
showPending = false;
showPaid = false;   // ✅ NEW
xeroUrl = null;

if (q.Status == 'Accepted' &&
    q.Xero_Invoices__r != null &&
    !q.Xero_Invoices__r.isEmpty()) {

    Xero_Invoice__c inv = q.Xero_Invoices__r[0];

    String paymentStatus = inv.Payment_Status__c;
    String paymentUrl = inv.Payment_URL__c;

    // ✅ Paid → show label
    if (paymentStatus == 'Paid') {
        showPaid = true;
    }

    // ✅ Payment link exists
    else if (!String.isBlank(paymentUrl)) {
        showPay = true;
        xeroUrl = paymentUrl;
    }

    // ✅ Pending approval
    else if (String.isBlank(paymentUrl) && paymentStatus == 'Unpaid') {
        showPending = true;
    }
}
        }
    }
}