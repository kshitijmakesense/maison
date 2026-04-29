public with sharing class MaisonPastEventsController {
    
 @AuraEnabled(cacheable=true)
public static PaginationWrapper getPastEvents(Integer pageNumber, Integer pageSize) {
    try {

        Id accountId = getCurrentUserAccountId();

        Integer offset = (pageNumber - 1) * pageSize;

        List<Order> pastEvents = [
            SELECT Id, Occasion__c, AccountId,
                   Venue_Address__c, Event_Date__c,
                   Number_of_Guests__c, Status,
                   TotalAmount, Order_Total_Amount__c,
                   Event_Outcome__c
            FROM Order
            WHERE (Event_Date__c < TODAY OR Status = 'Closed')
            AND AccountId = :accountId
            ORDER BY Event_Date__c DESC
            LIMIT :pageSize
            OFFSET :offset
        ];

        Integer totalRecords = [
            SELECT COUNT()
            FROM Order
            WHERE Event_Date__c < TODAY
            AND AccountId = :accountId
        ];

        // 🔥 Collect booking ids
        Set<Id> bookingIds = new Set<Id>();
        for (Order o : pastEvents) {
            bookingIds.add(o.Id);
        }

        // 🔥 Get contact
        Id contactId = [
            SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()
        ].ContactId;

        // 🔥 Get rated bookings
        Set<Id> ratedBookingIds = new Set<Id>();

        for (Staff_Rating__c sr : [
            SELECT Booking__c
            FROM Staff_Rating__c
            WHERE Booking__c IN :bookingIds
            AND Contact__c = :contactId
        ]) {
            ratedBookingIds.add(sr.Booking__c);
        }

        // 🔥 Get feedback bookings
Set<Id> feedbackBookingIds = new Set<Id>();

for (Feedback__c f : [
    SELECT Booking__c
    FROM Feedback__c
    WHERE Booking__c IN :bookingIds
    AND Contact__c = :contactId
]) {
    feedbackBookingIds.add(f.Booking__c);
}

        // 🔥 Build wrapper list
        List<EventWrapper> wrappedEvents = new List<EventWrapper>();

        for (Order o : pastEvents) {
            Boolean isRated = ratedBookingIds.contains(o.Id);
           Boolean hasFeedback = feedbackBookingIds.contains(o.Id);

wrappedEvents.add(new EventWrapper(o, isRated, hasFeedback));
        }

        // 🔥 Final wrapper
        PaginationWrapper wrapper = new PaginationWrapper();
        wrapper.events = wrappedEvents;
        wrapper.totalRecords = totalRecords;
        wrapper.pageNumber = pageNumber;
        wrapper.pageSize = pageSize;
        wrapper.totalPages = (Integer)Math.ceil((Decimal)totalRecords / pageSize);

        return wrapper;

    } catch (Exception e) {
        throw new AuraHandledException('Error fetching past events: ' + e.getMessage());
    }
}
    
      // Helper method to get current user's AccountId
    private static Id getCurrentUserAccountId() {
        try {
            
            
            
            
            // Get current user's ContactId
            User currentUser = [
                SELECT ContactId
                FROM User
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];
            
            // If user has no ContactId (internal user), return null
            if (currentUser.ContactId == null) {
                return null;
            }
            
            // Get AccountId from Contact
            Contact userContact = [
                SELECT AccountId
                FROM Contact
                WHERE Id = :currentUser.ContactId
                LIMIT 1
            ];
            
            return userContact.AccountId;
            
        } catch (Exception e) {
            // Return null if any error occurs
            return null;
        }
    }
    
    public class EventWrapper {
    @AuraEnabled public Order record;
    @AuraEnabled public Boolean isRated;
     @AuraEnabled public Boolean hasFeedback; // 🔥 ADD THIS

    public EventWrapper(Order record, Boolean isRated, Boolean hasFeedback) {
        this.record = record;
        this.isRated = isRated;
        this.hasFeedback = hasFeedback;
    }
}
    
    // Wrapper class for pagination
   public class PaginationWrapper {
    @AuraEnabled public List<EventWrapper> events;
    @AuraEnabled public Integer totalRecords;
    @AuraEnabled public Integer pageNumber;
    @AuraEnabled public Integer pageSize;
    @AuraEnabled public Integer totalPages;
}
}