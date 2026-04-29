@IsTest
private class BookingStaffAssignmentTriggerTest {

    @testSetup
    static void setupTestData() {

        // ---------------------------------------------------------
        // 1. Create Opportunity (Sydney Bookings)
        // ---------------------------------------------------------
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
            Email_Address__c = 'test@test.com',
            Event_Date__c = Date.today().addDays(10)
        );
        insert opp;

        // Contact auto-created by Flow
        Contact con = [
            SELECT Id
            FROM Contact
            WHERE Email = :opp.Email_Address__c
            LIMIT 1
        ];
        
        System.assertNotEquals(null, con, 'Contact was not auto-created by flow');

        // Create Account manually (flow won’t run fully in tests)
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Link Contact → Account
        con.AccountId = acc.Id;
        update con;

        // Link Opportunity → Account
        opp.AccountId = acc.Id;
        update opp;


        // ---------------------------------------------------------
        // 2. Create Staff
        // ---------------------------------------------------------
        Staff__c staff = new Staff__c(Name = 'Test Staff');
        insert staff;


        // ---------------------------------------------------------
        // 3. Create Orders
        // ---------------------------------------------------------
        Order order1 = new Order(
            Name = 'Order 1',
            Status = 'Confirmed',
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Event_Date__c = Date.today().addDays(5)
        );

        Order order2 = new Order(
            Name = 'Order 2',
            Status = 'Confirmed',
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Event_Date__c = Date.today().addDays(8)
        );

        insert new List<Order>{ order1, order2 };


        // ---------------------------------------------------------
        // 4. Create Booking Staff Assignments
        // ---------------------------------------------------------
        Booking_Staff_Assignment__c a1 = new Booking_Staff_Assignment__c(
            Staff__c = staff.Id,
            Booking_Order__c = order1.Id
        );

        Booking_Staff_Assignment__c a2 = new Booking_Staff_Assignment__c(
            Staff__c = staff.Id,
            Booking_Order__c = order2.Id
        );

        insert new List<Booking_Staff_Assignment__c>{ a1, a2 };
    }


    // ---------------------------------------------------------
    // TEST: After Insert
    // ---------------------------------------------------------
    @IsTest
    static void testAfterInsert() {

        Order ord = [
            SELECT Staff_Names__c
            FROM Order
            WHERE Name = 'Order 1'
            LIMIT 1
        ];

        System.assertEquals(
            'Test Staff',
            ord.Staff_Names__c,
            'After insert: Staff name must update on Order'
        );
    }


    // ---------------------------------------------------------
    // TEST: After Update
    // ---------------------------------------------------------
    @IsTest
    static void testAfterUpdate() {

        Booking_Staff_Assignment__c rec =
            [SELECT Id, Types_of_Staff__c FROM Booking_Staff_Assignment__c LIMIT 1];

        rec.Types_of_Staff__c = 'Senior Waiter';
        update rec;

        Order ord = [
            SELECT Staff_Names__c
            FROM Order
            WHERE Name = 'Order 1'
            LIMIT 1
        ];

        System.assertEquals(
            'Test Staff',
            ord.Staff_Names__c,
            'After update: Staff name must stay correct'
        );
    }


    // ---------------------------------------------------------
    // TEST: After Delete
    // ---------------------------------------------------------
    @IsTest
    static void testAfterDelete() {

        List<Booking_Staff_Assignment__c> recs =
            [SELECT Id FROM Booking_Staff_Assignment__c];

        delete recs;

        Order ord = [
            SELECT Staff_Names__c
            FROM Order
            WHERE Name = 'Order 1'
            LIMIT 1
        ];

        System.assertEquals(
            null,
            ord.Staff_Names__c,
            'After delete: Staff_Names__c must be cleared'
        );
    }


    // ---------------------------------------------------------
    // TEST: After Undelete
    // ---------------------------------------------------------
    @IsTest
    static void testAfterUndelete() {

        List<Booking_Staff_Assignment__c> recs =
            [SELECT Id FROM Booking_Staff_Assignment__c ALL ROWS];

        // Delete + Undelete
        delete recs;
        undelete recs;

        Order ord = [
            SELECT Staff_Names__c
            FROM Order
            WHERE Name = 'Order 1'
            LIMIT 1
        ];

        System.assertEquals(
            'Test Staff',
            ord.Staff_Names__c,
            'After undelete: Staff_Names__c must be recalculated'
        );
    }
}