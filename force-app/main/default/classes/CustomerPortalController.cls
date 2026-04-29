public with sharing class CustomerPortalController {

    // Utility method to get the current user's Account Id
    @AuraEnabled(cacheable=true)
    public static Id getCurrentUserAccountId() {
        User currentUser = [
            SELECT Id, ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        if (currentUser.ContactId != null) {
            Contact currentContact = [
                SELECT AccountId
                FROM Contact
                WHERE Id = :currentUser.ContactId
                LIMIT 1
            ];
            return currentContact.AccountId;
        }
        return null; // Return null if user is not linked to a Contact or Account
    }

    @AuraEnabled(cacheable=true)
    public static AccountSummaryDTO getAccountEventSummary() {
         Id accId = getCurrentUserAccountId();
        /*User currentUser = [
                SELECT Id, ContactId 
                FROM User 
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];

        Id accId;
        
        if(currentUser.ContactId != null){
            Contact currentContact = [
                    SELECT AccountId 
                    FROM Contact 
                    WHERE Id = :currentUser.ContactId
                    LIMIT 1
                ];
            accId = currentContact.AccountId;
        } 
          */

      List<Order> events = [
            SELECT Id, Name, Event_Title__c, Event_Date__c
            FROM Order
            WHERE AccountId = :accId 
            AND Event_Date__c >= TODAY 
            AND Status != 'Completed'
            ORDER BY Event_Date__c ASC
            LIMIT 3
        ];

        Integer totalEvents = [SELECT COUNT() FROM Order WHERE AccountId = :accId];
        Integer pendingQuotes = [SELECT COUNT() FROM Quote WHERE AccountId = :accId AND (Status = 'Draft' OR Status = 'Sent' OR Status = 'Viewed')];

        return new AccountSummaryDTO(totalEvents, pendingQuotes, events);
    }

    public class AccountSummaryDTO {
        @AuraEnabled public Integer totalEvents;
        @AuraEnabled public Integer pendingQuotes;
        @AuraEnabled public List<Order> upcomingEvents;
        public AccountSummaryDTO(Integer t, Integer p, List<Order> e) {
            totalEvents = t; pendingQuotes = p; upcomingEvents = e;
        }
    }
}