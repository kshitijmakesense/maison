public with sharing class WelcomeDashboardController {
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDashboardData() {
        Map<String, Object> result = new Map<String, Object>();

        User u = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (u.ContactId == null) return result;

        Contact c = [SELECT Id, AccountId FROM Contact WHERE Id = :u.ContactId LIMIT 1];
        Id accId = c.AccountId;
        if (accId == null) return result;

        // 1️⃣ Active Bookings
        Integer activeBookings = [
            SELECT COUNT()
            FROM Order
            WHERE AccountId = :accId AND Status != 'Completed'  AND Status != 'Cancelled' 
        ];
        result.put('activeBookings', activeBookings);

          // 1️⃣ Draft Bookings
        Integer draftBookings = [
            SELECT COUNT()
            FROM Order
            WHERE AccountId = :accId AND Status = 'Draft'
        ];
        result.put('draftBookings', draftBookings);

        // Pending Signatures

        Integer pendingSignatures = [
            SELECT COUNT()
            FROM Quote
            WHERE AccountId = :accId AND Status = 'Viewed'
        ];
        result.put('pendingSignatures', pendingSignatures);


        // 2️⃣ Outstanding Invoice Amount
       AggregateResult[] invoices = [
            SELECT SUM(Amount_Due__c) total
            FROM Xero_Invoice__c
            WHERE Account__c = :accId
        ];

        // Safely extract numeric value, even if query returns no rows or null
        Decimal outstanding = 0;
        if (!invoices.isEmpty()) {
            outstanding = (Decimal)invoices[0].get('total');
        }
        if (outstanding == null) {
            outstanding = 0;
        }

        result.put('outstandingAmount', outstanding);

       // 3️⃣ Completed Events
        Integer eventsComplete = [
            SELECT COUNT()
            FROM Order
            WHERE AccountId = :accId AND Status = 'Completed'
        ];
        result.put('eventsComplete', eventsComplete);
/*
 
        // 4️⃣ Average Response Time (example)
        AggregateResult[] responses = [
            SELECT AVG(Response_Time__c) avgResp
            FROM Service_Feedback__c
            WHERE Account__c = :accId
        ];
        result.put('avgResponse', responses.isEmpty() ? 0 : (Decimal)responses[0].get('avgResp'));

        // 5️⃣ Satisfaction Rating
        AggregateResult[] satisfaction = [
            SELECT AVG(Satisfaction__c) avgSat
            FROM Service_Feedback__c
            WHERE Account__c = :accId
        ];
        result.put('satisfaction', satisfaction.isEmpty() ? 0 : (Decimal)satisfaction[0].get('avgSat'));*/

        return result;
    }
}