@IsTest
private class MaisonBookingDetailsControllerTest {

    @IsTest
    static void testBookingDetailsFullFlow() {

        Date today = Date.today();

        // ----------------------------------
        // 1️⃣ Account
        // ----------------------------------
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // ----------------------------------
        // 2️⃣ Contact
        // ----------------------------------
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            AccountId = acc.Id,
            Phone = '9999999999',
            Email = 'test@test.com'
        );
        insert con;

        // ----------------------------------
        // 3️⃣ Opportunity (Required fields per your org)
        // ----------------------------------
        Id rtId = Schema.SObjectType.Opportunity
            .getRecordTypeInfosByName()
            .get('Sydney Bookings')
            .getRecordTypeId();

        Opportunity opp = new Opportunity(
            RecordTypeId = rtId,
            Name = 'Test Enquiry',
            StageName = 'Prospecting',
            CloseDate = today.addDays(5),
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Phone_Number__c = '9999999999',
            Email_Address__c = 'test@test.com',
            Event_Date__c = today.addDays(10),
            AccountId = acc.Id,
            Occasion__c = 'Corporate Event',
            Venue_Address__c = 'Sydney'
        );
        insert opp;

        // ----------------------------------
        // 4️⃣ Order
        // ----------------------------------
        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = today,
            OpportunityId = opp.Id,
            Contact__c = con.Id,
            Event_Date__c = today.addDays(10),
            Occasion__c = 'Corporate Event',
            Venue_Address__c = 'Sydney',
            Number_of_Guests__c = 50,
            Number_of_Staff_Required__c = 5
        );
        insert ord;

        // ----------------------------------
        // 5️⃣ Order Line Item (Custom Object)
        // ----------------------------------
        Order_Line_Item__c oli = new Order_Line_Item__c(
            Name = 'Test Line',
            Booking_Order__c = ord.Id,
            Quantity__c = 2,
            Unit_Price__c = 100,
            Tax_Rate__c = '10'
        );
        insert oli;

        // ----------------------------------
        // 6️⃣ Staff (Custom object assumed)
        // ----------------------------------
        Staff__c staff = new Staff__c(
            Name = 'Staff One',
            Last_Name__c = 'Smith'
        );
        insert staff;

       /* Booking_Staff_Assignment__c staffAssign =
            new Booking_Staff_Assignment__c(
                Booking_Order__c = ord.Id,
                Staff__c = staff.Id,
                Types_of_Staff__c = 'Senior Waiter'
            );
        insert staffAssign;*/

        // ----------------------------------
        // 7️⃣ Quote
        // ----------------------------------
        Quote qt = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Status = 'Draft'
        );
        insert qt;

        // ----------------------------------
        // 8️⃣ Invoice
        // ----------------------------------
        Xero_Invoice__c inv = new Xero_Invoice__c(
            Account__c = acc.Id,
            Quote__c = qt.Id,
            Xero_Invoice_Number__c = 'INV-001',
            Invoice_Date__c = today,
            Due_Date__c = today.addDays(7),
            Total_Amount__c = 1000,
            Invoice_Status__c = 'Submitted',
            Payment_Status__c = 'Unpaid',
            Amount_Due__c = 1000
        );
        insert inv;

        // ----------------------------------
        // 🔥 TEST METHODS
        // ----------------------------------

        Test.startTest();

        // Order details
        Order orderResult =
            MaisonBookingDetailsController.getOrderDetails(ord.Id);
        System.assertNotEquals(null, orderResult);
        System.assertEquals(ord.Id, orderResult.Id);

        // Line items
        List<Order_Line_Item__c> lines =
            MaisonBookingDetailsController.getOrderLineItems(ord.Id);
        System.assertEquals(1, lines.size());

        // Staff assignments
        List<Booking_Staff_Assignment__c> staffList =
            MaisonBookingDetailsController.getStaffAssignments(ord.Id);
        System.assertEquals(0, staffList.size());

        // Quotes
        List<Quote> quotes =
            MaisonBookingDetailsController.getQuotes(ord.Id);
        System.assertEquals(1, quotes.size());

        // Invoices
        Map<String, Object> invoiceMap =
            MaisonBookingDetailsController.getInvoices(ord.Id);

        List<Xero_Invoice__c> invoices =
            (List<Xero_Invoice__c>) invoiceMap.get('invoices');

        System.assertEquals(1, invoices.size());
        String orderNumberFromMap = String.valueOf(invoiceMap.get('orderNumber'));
System.assert(orderResult.OrderNumber != null);

        Test.stopTest();
    }

    // ----------------------------------
    // Edge Case: Order without Opportunity
    // ----------------------------------
    @IsTest
    static void testOrderWithoutOpportunity() {

        Account acc = new Account(Name='Acc2');
        insert acc;

        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today()
        );
        insert ord;

        Test.startTest();

        List<Quote> quotes =
            MaisonBookingDetailsController.getQuotes(ord.Id);
        System.assertEquals(0, quotes.size());

        Map<String,Object> invoiceMap =
            MaisonBookingDetailsController.getInvoices(ord.Id);

        List<Xero_Invoice__c> invoices =
            (List<Xero_Invoice__c>) invoiceMap.get('invoices');

        System.assertEquals(0, invoices.size());

        Test.stopTest();
    }
}