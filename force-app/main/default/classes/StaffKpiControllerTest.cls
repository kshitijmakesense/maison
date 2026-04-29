@IsTest
private class StaffKpiControllerTest {

    @IsTest
    static void testGetStaffKpi() {
        
        
        // --------------------------
        // 1. Create Opportunity (Sydney Bookings)
        // --------------------------
        Id rtId = Schema.SObjectType.Opportunity
            .getRecordTypeInfosByName()
            .get('Sydney Bookings')
            .getRecordTypeId();
		Date eventDay = Date.today().addDays(10);
        
        Opportunity opp = new Opportunity(
            RecordTypeId = rtId,
            Name = 'Test Enquiry',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(5),
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Phone_Number__c = '9999999999',
            Email_Address__c = 'test@test.com',
            Event_Date__c = eventDay
        );
        insert opp;
          // Flow creates Contact — fetch it
        Contact con = [
            SELECT Id
            FROM Contact
            WHERE Email = :opp.Email_Address__c
            LIMIT 1
        ];
        System.assertNotEquals(null, con, 'Contact was not auto-created by flow');

        // Create Account manually (flow won’t run in tests)
        Account acc = new Account(Name = 'Test Acc');
        insert acc;

        // Map Contact → Account
        con.AccountId = acc.Id;
        update con;

        // Map Opportunity → Account
        opp.AccountId = acc.Id;
        update opp;


        // --------------------------
        // 1. Create Staff
        // --------------------------
        Staff__c staff = new Staff__c(Name = 'Test Staff');
        insert staff;
        Id staffId = staff.Id;

        // --------------------------
        // 2. Create Orders (like AccountKpiControllerTest)
        // --------------------------

        // 2A. Upcoming Event (Event_Date__c >= TODAY)
        Order upcomingOrder1 = new Order(
            Name = 'Event Order 1',
            Status = 'Confirmed',
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Event_Date__c = Date.today().addDays(5)
        );

        // 2B. Upcoming Event
        Order upcomingOrder2 = new Order(
            Name = 'Event Order 2',
            Status = 'Confirmed',
             AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Event_Date__c = Date.today().addDays(8)
        );

        // 2C. This Month Event
        /*Order thisMonthOrder = new Order(
            Name = 'This Month Event Order',
            Status = 'Confirmed',
             AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Event_Date__c = Date.today().toStartOfMonth().addDays(7)
        );*/

        insert new List<Order>{
            upcomingOrder1, upcomingOrder2
        };

        // --------------------------
        // 3. Create Staff Assignments
        // --------------------------
        Booking_Staff_Assignment__c a1 = new Booking_Staff_Assignment__c(
            Staff__c = staffId,
            Booking_Order__c = upcomingOrder1.Id   // 🔥 NOTE: field must point to Order
        );

        Booking_Staff_Assignment__c a2 = new Booking_Staff_Assignment__c(
            Staff__c = staffId,
            Booking_Order__c = upcomingOrder2.Id
        );

        /*Booking_Staff_Assignment__c a3 = new Booking_Staff_Assignment__c(
            Staff__c = staffId,
            Booking_Order__c = thisMonthOrder.Id
        );*/

        insert new List<Booking_Staff_Assignment__c>{ a1, a2 };

        // --------------------------
        // 4. Add Staff Photo
        // --------------------------
        Attachment att = new Attachment(
            ParentId = staffId,
            Name = 'image.jpg',
            Body = Blob.valueOf('sample'),
            ContentType = 'image/jpeg'
        );
        insert att;

        // --------------------------
        // 5. Execute KPI Method
        // --------------------------
        Test.startTest();
        StaffKpiController.StaffKpiWrapper result =
            StaffKpiController.getStaffKpi(staffId);
        Test.stopTest();

        // --------------------------
        // 6. Assertions
        // --------------------------
        System.assertEquals(2, result.totalBookings,
            'Should count all bookings');

        System.assertEquals(2, result.upcomingEvents,
            'All 2 events has Event_Date__c >= today');

        System.assertEquals(0, result.completedEvents,
            'No event is Completed');

        System.assertEquals(2, result.eventsThisMonth,
            '2 events is in this month');

        System.assertNotEquals(null, result.photoUrl,
            'Photo URL must not be null');
    }
}