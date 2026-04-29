public with sharing class MaisonUpcomingEventController {
    
    @AuraEnabled(cacheable=true)
    public static List<Order> getUpcomingEvents() {
        try {
            // Get current user's AccountId
            Id accountId = getCurrentUserAccountId();
            
            // If no AccountId found, return empty summary
            if (accountId == null) {
                return  new List<Order>();
            }
            
            
            return [
                SELECT Id, Occasion__c,	AccountId, Venue_Address__c, Event_Date__c, Status,
                       Number_of_Guests__c, Event_Outcome__c, TotalAmount,Order_Total_Amount__c
                FROM Order
                WHERE Event_Date__c >= TODAY
                AND (Event_Outcome__c != 'Event Completed' AND Event_Outcome__c != 'Event Cancelled') AND AccountId = :accountId
                ORDER BY Event_Date__c ASC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching upcoming events: ' + e.getMessage());
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
}