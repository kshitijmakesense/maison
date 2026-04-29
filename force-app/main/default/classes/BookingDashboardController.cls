public with sharing class BookingDashboardController {
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getBookings(
        Id accountId,
        String status,
        Date startDate,
        Date endDate
    ) {
        Map<String, Object> result = new Map<String, Object>();

        // Build dynamic conditions
        String stageFilter = (status != null && status != '') ?
            ' AND StageName = :status ' : '';

        String orderStatusFilter = (status != null && status != '') ?
            ' AND Status = :status ' : '';

        String enquiryDateFilter = 
            (startDate != null ? ' AND Event_Date__c >= :startDate ' : '') +
            (endDate   != null ? ' AND Event_Date__c <= :endDate ' : '');

        String orderDateFilter = 
            (startDate != null ? ' AND Event_Date__c >= :startDate ' : '') +
            (endDate   != null ? ' AND Event_Date__c <= :endDate ' : '');

        // ----- ENQUIRIES -----
        List<Opportunity> enquiries = Database.query(
            'SELECT Id, Name, Event_Date__c, Number_of_Guests__c, Estimated_Budget__c, Venue_Address__c, StageName ' +
            'FROM Opportunity ' +
            'WHERE AccountId = :accountId ' +
            stageFilter +
            enquiryDateFilter +
            ' ORDER BY Event_Date__c DESC'
        );

        // ----- ORDERS -----
        List<Order> orders = Database.query(
            'SELECT Id, Name, Event_Date__c, Number_of_Guests__c, Venue_Address__c, Estimated_Budget__c, Status ' +
            'FROM Order ' +
            'WHERE AccountId = :accountId ' +
            orderStatusFilter +
            orderDateFilter +
            ' ORDER BY Event_Date__c DESC'
        );

        result.put('enquiries', enquiries);
        result.put('orders', orders);

        return result;
    }
}