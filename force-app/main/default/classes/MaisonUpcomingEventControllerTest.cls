@IsTest
private class MaisonUpcomingEventControllerTest {

    @IsTest
    static void testGetUpcomingEvents() {

        // -----------------------------------
        // 1️⃣ Create Account
        // -----------------------------------
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // -----------------------------------
        // 2️⃣ Create Contact
        // -----------------------------------
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            AccountId = acc.Id,
            Email = 'portal@test.com'
        );
        insert con;

        // -----------------------------------
        // 3️⃣ Get Portal Profile
        // -----------------------------------
        Profile portalProfile = [
            SELECT Id
            FROM Profile
            WHERE UserType IN ('CSPLitePortal','CustomerSuccess','PowerCustomerSuccess')
            LIMIT 1
        ];

        // -----------------------------------
        // 4️⃣ Create Portal User
        // -----------------------------------
        User portalUser = new User(
            FirstName = 'Portal',
            LastName = 'User',
            Email = 'portaluser@test.com',
            Username = 'portaluser' + DateTime.now().getTime() + '@test.com',
            Alias = 'puser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = portalProfile.Id,
            LanguageLocaleKey = 'en_US',
            ContactId = con.Id
        );
        insert portalUser;

        Date today = Date.today();

        // -----------------------------------
        // 5️⃣ Valid Upcoming Event (Should Return)
        // -----------------------------------
        Order validOrder = new Order(
            AccountId = acc.Id,
            Status = 'Draft', // Safe status
            EffectiveDate = today,
            Event_Date__c = today.addDays(5),
            Occasion__c = 'Corporate Event',
            Venue_Address__c = 'Sydney',
            Number_of_Guests__c = 40
        );
        insert validOrder;

        // -----------------------------------
        // 6️⃣ Past Event (Should NOT Return)
        // -----------------------------------
        /*Order pastOrder = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = today,
            Event_Date__c = today.addDays(-5),
            Occasion__c = 'Past Event',
            Venue_Address__c = 'Melbourne',
            Number_of_Guests__c = 25
        );
        insert pastOrder;*/

        // -----------------------------------
        // 7️⃣ Different Account (Should NOT Return)
        // -----------------------------------
        Account acc2 = new Account(Name = 'Other Account');
        insert acc2;

        Order otherAccountOrder = new Order(
            AccountId = acc2.Id,
            Status = 'Draft',
            EffectiveDate = today,
            Event_Date__c = today.addDays(10),
            Occasion__c = 'Other Event'
        );
        insert otherAccountOrder;

        // -----------------------------------
        // 🔐 Run As Portal User
        // -----------------------------------
        System.runAs(portalUser) {

            Test.startTest();

            List<Order> results =
                MaisonUpcomingEventController.getUpcomingEvents();

            Test.stopTest();

            // ✅ Only validOrder should return
            System.assertEquals(1, results.size());

            Order returnedOrder = results[0];

            System.assertEquals('Corporate Event', returnedOrder.Occasion__c);
            System.assertEquals('Sydney', returnedOrder.Venue_Address__c);
            System.assertEquals(40, returnedOrder.Number_of_Guests__c);
        }
    }

    // -----------------------------------
    // 🔹 Edge Case: User without Contact
    // -----------------------------------
    @IsTest
    static void testNoContactUser() {

        Test.startTest();

        List<Order> results =
            MaisonUpcomingEventController.getUpcomingEvents();

        Test.stopTest();

        System.assertEquals(0, results.size());
    }
}