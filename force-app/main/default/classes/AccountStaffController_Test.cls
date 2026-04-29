@isTest
private class AccountStaffController_Test {
    
    @testSetup
    static void setup() {
        // Create Account with required field
        Account testAccount = new Account(
            Name = 'Test Corporate Account',
            Customer_Type__c = 'Corporate' // Required field
        );
        insert testAccount;
        
        // Create Staff records with different roles and groups
        List<Staff__c> staffList = new List<Staff__c>();
        staffList.add(new Staff__c(
            Name = 'John',
            Last_Name__c = 'Doe',
            Role__c = 'Employee',
            Group__c = 'Melbourne' // Multi-select picklist with single value
        ));
        staffList.add(new Staff__c(
            Name = 'Jane',
            Last_Name__c = 'Smith',
            Role__c = 'Manager',
            Group__c = 'Sydney' // Multi-select picklist with single value
        ));
        staffList.add(new Staff__c(
            Name = 'Mike',
            Last_Name__c = 'Johnson',
            Role__c = 'Admin',
            Group__c = 'Melbourne;Sydney' // Multi-select picklist with multiple values
        ));
        insert staffList;
        
        // Create Orders with future Event Date (as per requirement)
        Date futureEventDate = Date.today().addDays(30);
        List<Order> orders = new List<Order>();
        orders.add(new Order(
            AccountId = testAccount.Id,
            Status = 'Draft', // Required field
            EffectiveDate = futureEventDate, // Order Start Date (required)
            Event_Date__c = futureEventDate, // Must be future
        //    Order_Total_Amount__c = 5000.00,
            Name = 'Corporate Event Order 1'
        ));
        orders.add(new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = futureEventDate,
            Event_Date__c = futureEventDate,
        //    Order_Total_Amount__c = 3000.00,
            Name = 'Corporate Event Order 2'
        ));
        orders.add(new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = futureEventDate,
            Event_Date__c = futureEventDate,
         //   Order_Total_Amount__c = null, // Test null handling
            Name = 'Corporate Event Order 3'
        ));
        insert orders;
        
        // Create Booking Staff Assignments
        List<Booking_Staff_Assignment__c> assignments = new List<Booking_Staff_Assignment__c>();
        
        // Order 1: Multiple staff assignments
        assignments.add(new Booking_Staff_Assignment__c(
            Booking_Order__c = orders[0].Id,
            Staff__c = staffList[0].Id,
            Types_of_Staff__c = 'Barista'
        ));
        assignments.add(new Booking_Staff_Assignment__c(
            Booking_Order__c = orders[0].Id,
            Staff__c = staffList[1].Id,
            Types_of_Staff__c = 'Server'
        ));
        
        // Order 2: Single staff with same person appearing again
        assignments.add(new Booking_Staff_Assignment__c(
            Booking_Order__c = orders[1].Id,
            Staff__c = staffList[0].Id, // Same staff as Order 1
            Types_of_Staff__c = 'Barista'
        ));
        assignments.add(new Booking_Staff_Assignment__c(
            Booking_Order__c = orders[1].Id,
            Staff__c = staffList[2].Id,
            Types_of_Staff__c = 'Chef'
        ));
        
        // Order 3: No staff assignments (edge case)
        
        insert assignments;
    }
    
    @isTest
    static void testGetStaffForAccount_WithMultipleOrders() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        List<AccountStaffController.StaffKpiWrapper> results = 
            AccountStaffController.getStaffForAccount(testAccount.Id);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(3, results.size(), 'Should return 3 unique staff members');
        
        // Find specific staff and verify KPIs
        AccountStaffController.StaffKpiWrapper johnDoe = findStaffByName(results, 'John');
        System.assertNotEquals(null, johnDoe, 'John Doe should be in results');
        System.assertEquals(2, johnDoe.orderCount, 'John should have 2 order assignments');
        System.assertEquals(8000.00, johnDoe.totalAmount, 'John total should be 8000 (5000 + 3000)');
        System.assertEquals('Employee', johnDoe.staffRole, 'John role should be Employee');
        System.assertEquals('Melbourne', johnDoe.staffGroup, 'John group should be Melbourne');
        
        AccountStaffController.StaffKpiWrapper janeSmith = findStaffByName(results, 'Jane');
        System.assertEquals(1, janeSmith.orderCount, 'Jane should have 1 order assignment');
        System.assertEquals(5000.00, janeSmith.totalAmount, 'Jane total should be 5000');
        
        AccountStaffController.StaffKpiWrapper mikeJohnson = findStaffByName(results, 'Mike');
        System.assertEquals(1, mikeJohnson.orderCount, 'Mike should have 1 order assignment');
        System.assertEquals(3000.00, mikeJohnson.totalAmount, 'Mike total should be 3000');
    }
    
    @isTest
    static void testGetStaffForAccount_NoOrders() {
        // Create new account with no orders
        Account newAccount = new Account(
            Name = 'Account Without Orders',
            Customer_Type__c = 'Individual'
        );
        insert newAccount;
        
        Test.startTest();
        List<AccountStaffController.StaffKpiWrapper> results = 
            AccountStaffController.getStaffForAccount(newAccount.Id);
        Test.stopTest();
        
        // Should return empty list
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(0, results.size(), 'Should return empty list when no orders exist');
    }
    
    @isTest
    static void testGetStaffForAccount_OrdersWithoutAssignments() {
        // Create account and order without staff assignments
        Account testAccount = new Account(
            Name = 'Account With Unassigned Order',
            Customer_Type__c = 'Government'
        );
        insert testAccount;
        
        Order unassignedOrder = new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = Date.today().addDays(15),
            Event_Date__c = Date.today().addDays(15),
          ///  Order_Total_Amount__c = 2000.00,
            Name = 'Unassigned Order'
        );
        insert unassignedOrder;
        
        Test.startTest();
        List<AccountStaffController.StaffKpiWrapper> results = 
            AccountStaffController.getStaffForAccount(testAccount.Id);
        Test.stopTest();
        
        // Should return empty list as no staff assignments exist
        System.assertEquals(0, results.size(), 'Should return empty list when orders have no staff');
    }
    
    @isTest
    static void testGetStaffForAccount_NullOrderAmount() {
        // Get account with Order 3 (null amount)
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Order orderWithNullAmount = [SELECT Id FROM Order WHERE Order_Total_Amount__c = null LIMIT 1];
        
        // Add assignment to the null-amount order
        Staff__c staff = [SELECT Id FROM Staff__c LIMIT 1];
        Booking_Staff_Assignment__c assignment = new Booking_Staff_Assignment__c(
            Booking_Order__c = orderWithNullAmount.Id,
            Staff__c = staff.Id,
            Types_of_Staff__c = 'Helper'
        );
        insert assignment;
        
        Test.startTest();
        List<AccountStaffController.StaffKpiWrapper> results = 
            AccountStaffController.getStaffForAccount(testAccount.Id);
        Test.stopTest();
        
        // Should handle null amounts gracefully
        System.assert(results.size() > 0, 'Should return results even with null order amounts');
        
        // Verify totals don't break with null
        for (AccountStaffController.StaffKpiWrapper kpi : results) {
            System.assertNotEquals(null, kpi.totalAmount, 'Total amount should never be null');
        }
    }
    
    @isTest
    static void testGetStaffForAccount_InvalidAccountId() {
        // Create a fake Account Id that doesn't exist
        Id fakeAccountId = '001000000000000AAA';
        
        Test.startTest();
        List<AccountStaffController.StaffKpiWrapper> results = 
            AccountStaffController.getStaffForAccount(fakeAccountId);
        Test.stopTest();
        
        // Should return empty list for non-existent account
        System.assertEquals(0, results.size(), 'Should return empty list for invalid account');
    }
    
    @isTest
    static void testGetStaffForAccount_BulkData() {
        // Test with larger data volume
        Account bulkAccount = new Account(
            Name = 'Bulk Test Account',
            Customer_Type__c = 'Specialist Customer'
        );
        insert bulkAccount;
        
        // Create 50 staff members
        List<Staff__c> bulkStaff = new List<Staff__c>();
        for (Integer i = 0; i < 50; i++) {
            // Rotate through roles and groups
            String role = Math.mod(i, 3) == 0 ? 'Admin' : (Math.mod(i, 3) == 1 ? 'Manager' : 'Employee');
            String groupValue = Math.mod(i, 3) == 0 ? 'Melbourne' : (Math.mod(i, 3) == 1 ? 'Sydney' : 'Melbourne;Sydney');
            
            bulkStaff.add(new Staff__c(
                Name = 'Staff' + i,
                Last_Name__c = 'Bulk' + i,
                Role__c = role,
                Group__c = groupValue
            ));
        }
        insert bulkStaff;
        
        // Create 20 orders
        List<Order> bulkOrders = new List<Order>();
        for (Integer i = 0; i < 20; i++) {
            bulkOrders.add(new Order(
                AccountId = bulkAccount.Id,
                Status = 'Draft',
                EffectiveDate = Date.today().addDays(10),
                Event_Date__c = Date.today().addDays(10),
            //    Order_Total_Amount__c = 1000.00,
                Name = 'Bulk Order ' + i
            ));
        }
        insert bulkOrders;
        
        // Create assignments (multiple staff per order)
        List<Booking_Staff_Assignment__c> bulkAssignments = new List<Booking_Staff_Assignment__c>();
        for (Order ord : bulkOrders) {
            for (Integer i = 0; i < 5; i++) {
                bulkAssignments.add(new Booking_Staff_Assignment__c(
                    Booking_Order__c = ord.Id,
                    Staff__c = bulkStaff[i].Id,
                    Types_of_Staff__c = 'Server'
                ));
            }
        }
        insert bulkAssignments;
        
        Test.startTest();
        List<AccountStaffController.StaffKpiWrapper> results = 
            AccountStaffController.getStaffForAccount(bulkAccount.Id);
        Test.stopTest();
        
        // Verify bulk processing
        System.assertEquals(5, results.size(), 'Should return 5 unique staff members');
        
        // Each staff member should have 20 assignments (one per order)
        for (AccountStaffController.StaffKpiWrapper kpi : results) {
            System.assertEquals(20, kpi.orderCount, 'Each staff should have 20 assignments');
            System.assertEquals(20000.00, kpi.totalAmount, 'Each staff total should be 20000');
        }
    }
    
    @isTest
    static void testStaffKpiWrapper_Constructor() {
        // Test wrapper class directly
        Test.startTest();
        AccountStaffController.StaffKpiWrapper wrapper = 
            new AccountStaffController.StaffKpiWrapper(
                '001000000000001AAA',
                'Test Name',
                'Test Role',
                'Test Group'
            );
        Test.stopTest();
        
        // Verify initialization
        System.assertEquals('001000000000001AAA', wrapper.staffId);
        System.assertEquals('Test Name', wrapper.staffName);
        System.assertEquals('Test Role', wrapper.staffRole);
        System.assertEquals('Test Group', wrapper.staffGroup);
        System.assertEquals(0, wrapper.orderCount, 'Order count should initialize to 0');
        System.assertEquals(0, wrapper.totalAmount, 'Total amount should initialize to 0');
    }
    
    // Helper method to find staff by name in results
    private static AccountStaffController.StaffKpiWrapper findStaffByName(
        List<AccountStaffController.StaffKpiWrapper> results, 
        String firstName
    ) {
        for (AccountStaffController.StaffKpiWrapper kpi : results) {
            if (kpi.staffName == firstName) {
                return kpi;
            }
        }
        return null;
    }
}