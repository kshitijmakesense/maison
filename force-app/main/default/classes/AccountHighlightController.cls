/* ===== AccountHighlightController.cls (Apex Controller) ===== */
public with sharing class AccountHighlightController {
    
    public class AccountDetails {
        @AuraEnabled public Integer orderCount { get; set; }
        @AuraEnabled public Integer enquiryCount { get; set; }
       // @AuraEnabled public Decimal creditLimit { get; set; }
    }
    
    @AuraEnabled(cacheable=true)
    public static AccountDetails getAccountDetails(Id accountId) {
        AccountDetails details = new AccountDetails();
        
        try {
            // Get Order Count
            details.orderCount = [SELECT COUNT() FROM Order WHERE AccountId = :accountId];
            
            // Get Enquiry/Opportunity Count
            details.enquiryCount = [SELECT COUNT() FROM Opportunity WHERE AccountId = :accountId];
            
        // Get Credit Limit from Account
          //  Account acc = [SELECT Credit_Limit__c FROM Account WHERE Id = :accountId LIMIT 1];
          //  details.creditLimit = acc.Credit_Limit__c != null ? acc.Credit_Limit__c : 0;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving account details: ' + e.getMessage());
        }
        
        return details;
    }
}