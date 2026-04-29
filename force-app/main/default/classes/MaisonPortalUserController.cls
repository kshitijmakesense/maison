public with sharing class MaisonPortalUserController {

    @AuraEnabled(cacheable=true)
    public static User getCurrentUser() {
        return [
            SELECT Id, Name, Email, SmallPhotoUrl
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
    }
}