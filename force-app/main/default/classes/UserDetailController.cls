public with sharing class UserDetailController {
    
    @AuraEnabled(cacheable=true)
    public static UserData getUserDetails(Id userId) {
        try {
            User userRecord = [
                SELECT Id, Name, Email, Street, City, State, PostalCode, Country, 
                       MobilePhone, Phone, CompanyName
                FROM User 
                WHERE Id = :userId 
                LIMIT 1
            ];
            
            UserData userData = new UserData();
            userData.name = userRecord.Name;
            userData.senderEmail = userRecord.Email;
            userData.phone = userRecord.MobilePhone != null ? userRecord.MobilePhone : userRecord.Phone;
            userData.companyName = userRecord.CompanyName;
            
            // Combine address fields
            List<String> addressParts = new List<String>();
            if (String.isNotBlank(userRecord.Street)) {
                addressParts.add(userRecord.Street);
            }
            if (String.isNotBlank(userRecord.City)) {
                addressParts.add(userRecord.City);
            }
            if (String.isNotBlank(userRecord.State)) {
                addressParts.add(userRecord.State);
            }
            if (String.isNotBlank(userRecord.PostalCode)) {
                addressParts.add(userRecord.PostalCode);
            }
            if (String.isNotBlank(userRecord.Country)) {
                addressParts.add(userRecord.Country);
            }
            
            userData.address = String.join(addressParts, ', ');
            
            return userData;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving user details: ' + e.getMessage());
        }
    }
    
    // Wrapper class to return user data
    public class UserData {
        @AuraEnabled public String name;
        @AuraEnabled public String senderEmail;
        @AuraEnabled public String address;
        @AuraEnabled public String phone;
        @AuraEnabled public String companyName;
    }
}