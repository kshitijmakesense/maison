@IsTest
private class MaisonPortalUserControllerTest {

    @IsTest
    static void testGetCurrentUser() {
        
        // Create a test user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );

        insert testUser;

        System.runAs(testUser) {
            
            Test.startTest();
            User result = MaisonPortalUserController.getCurrentUser();
            Test.stopTest();

            System.assertNotEquals(null, result);
            System.assertEquals(testUser.Id, result.Id);
            System.assertEquals(testUser.Email, result.Email);
        }
    }
}