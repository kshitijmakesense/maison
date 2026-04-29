public with sharing class QuarterlyInsightController {
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getQuarterInsights(Id accountId) {
        
        Map<String, Object> response = new Map<String, Object>();

        if (accountId == null) {
            return response;
        }

        Date today = Date.today();
        Integer year = today.year();

        // ------ CURRENT QUARTER ------
        Integer currentQuarter = ((today.month() - 1) / 3) + 1;

        Date currentQuarterStart = Date.newInstance(year, ((currentQuarter - 1) * 3) + 1, 1);
        Date currentQuarterEnd = currentQuarterStart.addMonths(3).addDays(-1);

        // ------ LAST QUARTER ------
        Integer lastQuarter = currentQuarter - 1;
        Integer lastQuarterYear = year;

        if (lastQuarter == 0) {
            lastQuarter = 4;
            lastQuarterYear = year - 1;
        }

        Date lastQuarterStart = Date.newInstance(lastQuarterYear, ((lastQuarter - 1) * 3) + 1, 1);
        Date lastQuarterEnd = lastQuarterStart.addMonths(3).addDays(-1);

        // ---------------------------
        //       SOQL QUERIES
        // ---------------------------
        List<Order> thisQ = [
            SELECT Id, Order_Total_Amount__c, Number_of_Guests__c, Event_Date__c
            FROM Order
            WHERE AccountId = :accountId
            AND Status = 'Completed'
            AND Event_Date__c >= :currentQuarterStart
            AND Event_Date__c <= :currentQuarterEnd
        ];

        List<Order> lastQ = [
            SELECT Id
            FROM Order
            WHERE AccountId = :accountId
            AND Status = 'Completed'
            AND Event_Date__c >= :lastQuarterStart
            AND Event_Date__c <= :lastQuarterEnd
        ];

        // ---------------------------
        //       METRICS
        // ---------------------------
        Integer completed = thisQ.size();
        Decimal totalInvestment = 0;
        Decimal totalGuests = 0;

        for (Order o : thisQ) {
            totalInvestment += (o.Order_Total_Amount__c != null ? o.Order_Total_Amount__c : 0);
            totalGuests += (o.Number_of_Guests__c != null ? o.Number_of_Guests__c : 0);
        }

        Decimal avgGuests = completed > 0 ? (Decimal)totalGuests / completed : 0;
        Decimal percentIncrease = 0;

        if (lastQ.size() > 0) {
            percentIncrease = ((Decimal)completed - lastQ.size()) / lastQ.size() * 100;
        }

        // ---------------------------
        //       FINAL RESPONSE
        // ---------------------------
        response.put('completed', completed);
        response.put('investment', totalInvestment);
        response.put('avgGuests', avgGuests);
        response.put('trend', percentIncrease);

        return response;
    }
}