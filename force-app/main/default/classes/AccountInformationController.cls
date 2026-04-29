public with sharing class AccountInformationController {

    /**
     * Fetch account details for the current user
     * @param userId - The Id of the logged-in user
     * @return Account - account associated with the user
     */
    @AuraEnabled(cacheable=true)
    public static Account getAccountDetails(Id userId) {
        try {
            // Get user's AccountId
            User currentUser = [
                SELECT Id, AccountId 
                FROM User 
                WHERE Id = :userId 
               // WITH SECURITY_ENFORCED 
                LIMIT 1
            ];

            if (currentUser.AccountId == null) {
                throw new AuraHandledException('No account associated with this user.');
            }

            // Fetch account details
            Account accountRecord = [
                SELECT 
                    Id,
                    Name,
                    Type,
                    Industry,
                    Phone,
                    BillingStreet,
                    BillingCity,
                    BillingState,
                    BillingPostalCode,
                    BillingCountry,
                    ShippingStreet,
                    ShippingCity,
                    ShippingState,
                    ShippingPostalCode,
                    ShippingCountry,
                    Email__c,
                    Website
                FROM Account 
                WHERE Id = :currentUser.AccountId 
               // WITH SECURITY_ENFORCED 
                LIMIT 1
            ];

            return accountRecord;

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving account details: ' + e.getMessage());
        }
    }

}