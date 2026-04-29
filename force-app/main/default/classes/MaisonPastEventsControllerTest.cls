@IsTest
private class MaisonPastEventsControllerTest {

    @IsTest
    static void testGetPastEvents() {

        // -------------------------
        // 1️⃣ Account
        // -------------------------
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // -------------------------
        // 2️⃣ Contact
        // -------------------------
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            AccountId = acc.Id,
            Email = 'portal@test.com'
        );
        insert con;

        // -------------------------
        // 3️⃣ Portal Profile
        // -------------------------
        Profile portalProfile = [
            SELECT Id
            FROM Profile
            WHERE UserType IN ('CSPLitePortal','CustomerSuccess','PowerCustomerSuccess')
            LIMIT 1
        ];

        // -------------------------
        // 4️⃣ Portal User
        // -------------------------
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

        // -------------------------
        // 🔥 Assign Bypass Permission Set
        // -------------------------
        PermissionSet ps = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = 'Bypass_Event_Date_Validation_PS'
            LIMIT 1
        ];

        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert new PermissionSetAssignment(
                AssigneeId = portalUser.Id,
                PermissionSetId = ps.Id
            );
        }

        Date today = Date.today();

        // -------------------------
        // 5️⃣ Past Event (Valid)
        // -------------------------
        Order pastOrder = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = today,
            Event_Date__c = today.addDays(-10),
            Occasion__c = 'Corporate Event',
            Venue_Address__c = 'Sydney',
            Number_of_Guests__c = 50
        );
        insert pastOrder;

        // -------------------------
        // 6️⃣ Future Event (Should NOT return)
        // -------------------------
        Order futureOrder = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = today,
            Event_Date__c = today.addDays(5),
            Occasion__c = 'Future Event'
        );
        insert futureOrder;

        // -------------------------
        // 7️⃣ Different Account (Should NOT return)
        // -------------------------
        Account acc2 = new Account(Name = 'Other Account');
        insert acc2;

        Order otherAccountOrder = new Order(
            AccountId = acc2.Id,
            Status = 'Draft',
            EffectiveDate = today,
            Event_Date__c = today.addDays(-5)
        );
        insert otherAccountOrder;

        // -------------------------
        // 🔐 Run As Portal User
        // -------------------------
        System.runAs(portalUser) {

            Test.startTest();

            MaisonPastEventsController.PaginationWrapper result =
                MaisonPastEventsController.getPastEvents(1, 10);

            Test.stopTest();

            System.assertEquals(1, result.events.size());
            System.assertEquals(1, result.totalRecords);
            System.assertEquals(1, result.pageNumber);
            System.assertEquals(10, result.pageSize);
            System.assertEquals(1, result.totalPages);

            Order returned = result.events[0];

            System.assertEquals('Corporate Event', returned.Occasion__c);
        }
    }

    @IsTest
    static void testNoContactUser() {

        Test.startTest();

        MaisonPastEventsController.PaginationWrapper result =
            MaisonPastEventsController.getPastEvents(1, 10);

        Test.stopTest();

        System.assertEquals(0, result.events.size());
    }
}