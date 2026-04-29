public with sharing class MaisonQuotesSummaryService {

    @AuraEnabled(cacheable=true)
    public static QuoteSummaryDTO getQuoteSummary() {

        User u = [
            SELECT ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        if (u.ContactId == null) return new QuoteSummaryDTO();

        Contact c = [
            SELECT AccountId
            FROM Contact
            WHERE Id = :u.ContactId
            LIMIT 1
        ];
        if (c.AccountId == null) return new QuoteSummaryDTO();

        List<Quote> quotes = [
            SELECT Id, Status, GrandTotal, Total_Price_Including_Tax__c
            FROM Quote
            WHERE AccountId = :c.AccountId
        ];

        Integer totalQuotes = quotes.size();
        Integer pending = 0;
        Integer accepted = 0;
        Decimal totalValue = 0;

        for (Quote q : quotes) {
            if ((q.Status == 'Sent') || (q.status == 'Viewed')) {
                pending++;
            }
            if (q.Status == 'Accepted') {
                accepted++;
                totalValue += q.Total_Price_Including_Tax__c != null ? q.Total_Price_Including_Tax__c : 0;
            }
        }

        return new QuoteSummaryDTO(
            totalQuotes,
            pending,
            accepted,
            totalValue
        );
    }

    public class QuoteSummaryDTO {
        @AuraEnabled public Integer totalQuotes;
        @AuraEnabled public Integer pendingReview;
        @AuraEnabled public Integer accepted;
        @AuraEnabled public Decimal totalValue;

        public QuoteSummaryDTO() {}

        public QuoteSummaryDTO(
            Integer t,
            Integer p,
            Integer a,
            Decimal v
        ) {
            totalQuotes = t;
            pendingReview = p;
            accepted = a;
            totalValue = v;
        }
    }
}