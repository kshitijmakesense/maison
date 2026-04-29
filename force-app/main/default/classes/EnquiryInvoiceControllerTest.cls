@IsTest
private class EnquiryInvoiceControllerTest {

    @IsTest
    static void testGetInvoices() {

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
        // 2. Create Quote linked to Enquiry
        // --------------------------
        Quote qt = new Quote(
            Name = 'Quote - Test',
            OpportunityId = opp.Id,
            Status = 'Draft'
        );
        insert qt;

        // --------------------------
        // 3. Create Invoice linked to the Quote
        // --------------------------
        Xero_Invoice__c inv = new Xero_Invoice__c(
            Account__c = acc.Id,
            Quote__c = qt.Id,
            Xero_Invoice_Number__c = 'INV-001',
            Invoice_Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(7),
            Total_Amount__c = 2500,
            Payment_Status__c = 'Unpaid',
            Invoice_Status__c = 'Submitted',
            Amount_Due__c = 2500
        );
        insert inv;

        // --------------------------
        // 4. Run Controller
        // --------------------------
        Test.startTest();
        List<Xero_Invoice__c> result =
            EnquiryInvoiceController.getInvoices(opp.Id);
        Test.stopTest();

        // --------------------------
        // 5. Assertions
        // --------------------------
        System.assertEquals(1, result.size(), 'Should return 1 invoice');
        System.assertEquals(inv.Id, result[0].Id, 'Returned invoice must match the created one');
        System.assertEquals(qt.Id, result[0].Quote__c, 'Invoice should be linked to correct quote');
    }
}