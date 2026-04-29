public without sharing class AccountManagerController {

    @AuraEnabled(cacheable=true)
    public static User getAccountManager(Id accountId) {

        Account acct = [
            SELECT Id, Account_Manager__c,
                Account_Manager__r.Name,
                Account_Manager__r.Title,
                Account_Manager__r.Phone,
                Account_Manager__r.Email,
                Account_Manager__r.SmallPhotoUrl
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        return acct.Account_Manager__r;
    }
}