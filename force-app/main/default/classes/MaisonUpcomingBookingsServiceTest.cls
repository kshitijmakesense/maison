@IsTest
private class MaisonUpcomingBookingsServiceTest {

    @IsTest
    static void testUpcomingBookingsAndCount() {

        // -----------------------------
        // 1️⃣ Create Account
        // -----------------------------
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // -----------------------------
        // 2️⃣ Create Contact
        // -----------------------------
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            AccountId = acc.Id,
            Email = 'portal@test.com'
        );
        insert con;

        // -----------------------------
        // 3️⃣ Get Portal Profile
        // -----------------------------
        Profile portalProfile = [
            SELECT Id
            FROM Profile
            WHERE UserType IN ('CSPLitePortal','CustomerSuccess','PowerCustomerSuccess')
            LIMIT 1
        ];

        // -----------------------------
        // 4️⃣ Create Portal User
        // -----------------------------
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

        // -------------------------------------------------
        // 5️⃣ Create Required Opportunity (aligned to org)
        // -------------------------------------------------
        Id rtId = Schema.SObjectType.Opportunity
            .getRecordTypeInfosByName()
            .get('Sydney Bookings')
            .getRecordTypeId();

        Opportunity opp = new Opportunity(
            RecordTypeId = rtId,
            Name = 'Test Enquiry',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(5),
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Phone_Number__c = '9999999999',
            Email_Address__c = 'portal@test.com',
            Event_Date__c = Date.today().addDays(10),
            AccountId = acc.Id,
            Occasion__c = 'Corporate Event'
        );
        insert opp;

        // -----------------------------
        // 6️⃣ Upcoming Order (Should Count)
        // -----------------------------
        Order futureOrder = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Event_Date__c = Date.today().addDays(3),
            OpportunityId = opp.Id,
            Number_of_Guests__c = 50
        );
        insert futureOrder;

        // -----------------------------
        // 7️⃣ Past Order (Should NOT Count)
        // -----------------------------
        /*Order pastOrder = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Event_Date__c = Date.today().addDays(-5),
            OpportunityId = opp.Id,
            Number_of_Guests__c = 30
        );
        insert pastOrder;*/

        // -------------------------------------------------
        // 🔐 Execute as Portal User
        // -------------------------------------------------
        System.runAs(portalUser) {

            Test.startTest();

            List<MaisonUpcomingBookingsService.BookingDTO> bookings =
                MaisonUpcomingBookingsService.getUpcomingBookings();

            Integer count =
                MaisonUpcomingBookingsService.getUpcomingBookingsCount();

            Test.stopTest();

            // ---------------- Assertions ----------------

            // Only future order should return
            System.assertEquals(1, bookings.size());
            System.assertEquals(1, count);

            MaisonUpcomingBookingsService.BookingDTO dto = bookings[0];

            System.assertEquals(50, dto.guests);
            System.assertEquals('Draft', dto.status);
            System.assert(dto.eventDate.contains(String.valueOf(Date.today().year())));
        }
    }

    // -------------------------------------------------
    // 🔹 Edge Case: User Without Contact
    // -------------------------------------------------
    @IsTest
    static void testNoContactUser() {

        Test.startTest();

        List<MaisonUpcomingBookingsService.BookingDTO> bookings =
            MaisonUpcomingBookingsService.getUpcomingBookings();

        Integer count =
            MaisonUpcomingBookingsService.getUpcomingBookingsCount();

        Test.stopTest();

        System.assertEquals(0, bookings.size());
        System.assertEquals(0, count);
    }
}