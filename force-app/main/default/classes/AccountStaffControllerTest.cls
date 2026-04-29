@IsTest
private class AccountStaffControllerTest {

    @IsTest
    static void testGetStaffForAccount() {
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


        // -------------------------------
        // 1. Create Staff Member
        // -------------------------------
        Staff__c staff1 = new Staff__c(
            Name = 'John Staff'
        );
        insert staff1;

        Staff__c staff2 = new Staff__c(
            Name = 'Mary Staff'
        );
        insert staff2;

     
        // -------------------------------
        // 3. Create Orders for that Account
        // -------------------------------
        Order ord1 = new Order(
            Name = 'Order 1',
            AccountId = acc.Id,
            Status = 'Confirmed',
            EffectiveDate = Date.today(),
            Event_Date__c = Date.today().addDays(5)
        );

        Order ord2 = new Order(
            Name = 'Order 2',
            AccountId = acc.Id,
            Status = 'Confirmed',
            EffectiveDate = Date.today(),
            Event_Date__c = Date.today().addDays(5)
        );

        insert new List<Order>{ ord1, ord2 };

        // -------------------------------
        // 4. Create Staff Assignments
        // -------------------------------
        Booking_Staff_Assignment__c assign1 = new Booking_Staff_Assignment__c(
            Staff__c = staff1.Id,
            Booking_Order__c = ord1.Id
        );

        Booking_Staff_Assignment__c assign2 = new Booking_Staff_Assignment__c(
            Staff__c = staff1.Id,
            Booking_Order__c = ord2.Id
        );

        Booking_Staff_Assignment__c assign3 = new Booking_Staff_Assignment__c(
            Staff__c = staff2.Id,
            Booking_Order__c = ord1.Id
        );

        insert new List<Booking_Staff_Assignment__c>{ assign1, assign2, assign3 };

        // -------------------------------
        // 5. Call Method Under Test
        // -------------------------------
        Test.startTest();
        List<AccountStaffController.StaffKpiWrapper> result =
            AccountStaffController.getStaffForAccount(acc.Id);
        Test.stopTest();

        // -------------------------------
        // 6. Assertions
        // -------------------------------
        System.assertEquals(2, result.size(), 'There should be 2 staff records returned');

        // Convert list to map for easy assertions
        Map<Id, AccountStaffController.StaffKpiWrapper> resultMap = new Map<Id, AccountStaffController.StaffKpiWrapper>();
        for (AccountStaffController.StaffKpiWrapper k : result) {
            resultMap.put(k.staffId, k);
        }

        // Staff 1 → has 2 assignments (1500 + 2500)
        System.assertEquals(2, resultMap.get(staff1.Id).orderCount, 'Staff1 order count mismatch');
        //System.assertEquals(4000, resultMap.get(staff1.Id).totalAmount, 'Staff1 total amount mismatch');

        // Staff 2 → has 1 assignment (1500)
        System.assertEquals(1, resultMap.get(staff2.Id).orderCount, 'Staff2 order count mismatch');
        //System.assertEquals(1500, resultMap.get(staff2.Id).totalAmount, 'Staff2 total amount mismatch');
    }
}