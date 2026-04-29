public with sharing class MaisonUpcomingBookingsService {

    @AuraEnabled(cacheable=true)
    public static List<BookingDTO> getUpcomingBookings() {

        User u = [
            SELECT ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        if (u.ContactId == null) return new List<BookingDTO>();

        Contact c = [
            SELECT AccountId
            FROM Contact
            WHERE Id = :u.ContactId
            LIMIT 1
        ];
        if (c.AccountId == null) return new List<BookingDTO>();

        List<Order> orders = [
            SELECT Id,
                   Name,
                   OrderNumber,
                   Status,
                   Event_Date__c,
                   Number_of_Guests__c,
                   Opportunity.Occasion__c
            FROM Order
            WHERE AccountId = :c.AccountId
            AND Event_Date__c >= :Date.today()
            ORDER BY Event_Date__c ASC
            LIMIT 5
        ];

        List<BookingDTO> result = new List<BookingDTO>();
        for (Order o : orders) {
            result.add(new BookingDTO(o));
        }
        return result;
    }

     @AuraEnabled(cacheable=true)
    public static Integer getUpcomingBookingsCount() {

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
            FROM Order
            WHERE AccountId = :c.AccountId
            AND Event_Date__c >= :Date.today()
             AND Status NOT IN ('Closed')
        ];
    }

    public class BookingDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public String title;
        @AuraEnabled public String bookingNumber;
        @AuraEnabled public String eventDate;
        @AuraEnabled public Integer guests;
        @AuraEnabled public String status;

        public BookingDTO(Order o) {
            id = o.Id;
            title = o.Opportunity != null ? o.Opportunity.Occasion__c : o.Name;
            bookingNumber = o.OrderNumber;
            guests = (Integer) o.Number_of_Guests__c;
            status = o.Status;
            if (o.Event_Date__c != null) {
        DateTime dt = DateTime.newInstance(
            o.Event_Date__c,
            Time.newInstance(0, 0, 0, 0)
        );
        eventDate = dt.format('MMM d, yyyy');
    }
          
        }
    }
}