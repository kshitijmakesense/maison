public with sharing class UserProfileController {
    /**
     * Gets the current user's details
     * @return User record with basic fields
     */
    @AuraEnabled(cacheable=true)
    public static User getUserDetails() {
        Id userId = UserInfo.getUserId();
        return [SELECT Id, Name, AccountId,Email, SmallPhotoUrl  
                FROM User 
                WHERE Id = :userId 
                //WITH SECURITY_ENFORCED 
                LIMIT 1];
    }
    
    /**
     * Gets the user's profile picture URL
     * @return String URL to the profile picture
     */
    @AuraEnabled(cacheable=true)
    public static String getProfilePicture() {
        try {
            Id userId = UserInfo.getUserId();
            User userRecord = [SELECT SmallPhotoUrl, FullPhotoUrl 
                              FROM User 
                              WHERE Id = :userId 
                              //WITH SECURITY_ENFORCED 
                              LIMIT 1];
            
            // Return the full photo URL if available
            return userRecord.FullPhotoUrl;
        } catch (Exception e) {
            return null;
        }
    }
}