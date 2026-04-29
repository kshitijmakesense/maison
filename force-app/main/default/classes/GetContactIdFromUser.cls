public with sharing class GetContactIdFromUser {
 
    @AuraEnabled(cacheable=true)
    public static Id getCurrentContactId() {
        return [
            SELECT ContactId 
            FROM User 
            WHERE Id = :UserInfo.getUserId()
        ].ContactId;
    }
}