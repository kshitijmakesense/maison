public with sharing class WelcomeBannerController {
    @AuraEnabled(cacheable=true)
    public static Account getAccountForUser() {
        User currentUser = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (currentUser.ContactId == null) return null;

        Contact c = [
            SELECT Id, AccountId, Account.Name, Account.Account_Manager__r.Name
            FROM Contact
            WHERE Id = :currentUser.ContactId
            LIMIT 1
        ];
        return c.Account;
    }
}