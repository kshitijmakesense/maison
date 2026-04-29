@IsTest
private class QuoteInvoiceControllerTest {

    @IsTest
    static void testGetInvoices() {

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
            StageName = 'New Enquiry',
            CloseDate = Date.today().addDays(5),
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Phone_Number__c = '9999999999',
            Email_Address__c = 'test@test.com',
            Event_Date__c = eventDay
        );
        insert opp;

        // --------------------------
        // 2. Create Quote linked to Opportunity
        //    (AccountId auto-populates from Opp)
        // --------------------------
        Quote qt = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Status = 'Draft'
        );
        insert qt;

         // --------------------------
        // 1A. Get Flow-Created Contact
        // --------------------------
        Contact createdCon = [
            SELECT Id, AccountId
            FROM Contact
            WHERE Email = :opp.Email_Address__c
            LIMIT 1
        ];
        System.assertNotEquals(null, createdCon, 'Flow did not auto-create Contact');

        // --------------------------
        // 2. Create Account & Map Contact + Opportunity
        // --------------------------
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        createdCon.AccountId = acc.Id;
        update createdCon;

        opp.AccountId = acc.Id;
        update opp;

        Id accId = acc.Id;

        // Re-query quote to confirm AccountId is set automatically
        /*qt = [
            SELECT Id, AccountId
            FROM Quote
            WHERE Id = :qt.Id
        ];

        System.assertNotEquals(null, qt.AccountId,
            'Quote.AccountId should auto-populate from Opportunity');*/

        // --------------------------
        // 3. Create Invoices linked to Quote
        // --------------------------
        Xero_Invoice__c inv1 = new Xero_Invoice__c(
            Account__c = accId,
            Quote__c = qt.Id,
            Xero_Invoice_Number__c = 'INV-001',
            Invoice_Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(5),
            Total_Amount__c = 1000,
            Invoice_Status__c = 'Submitted',
            Payment_Status__c = 'Unpaid',
            Amount_Due__c = 1000
        );

     

        insert new List<Xero_Invoice__c>{ inv1 };

        // --------------------------
        // 4. Call Controller
        // --------------------------
        Test.startTest();
        List<Xero_Invoice__c> result =
            QuoteInvoiceController.getInvoices(qt.Id);
        Test.stopTest();

        // --------------------------
        // 5. Assertions
        // --------------------------
        System.assertEquals(1, result.size(),
            'Controller should return 1 invoice related to the quote');

       
    }
}