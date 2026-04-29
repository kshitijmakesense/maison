@IsTest
private class MaisonOutstandingBalanceServiceTest {

    @IsTest
    static void testOutstandingSummary() {

        // -----------------------------
        // 1️⃣ Account
        // -----------------------------
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // -----------------------------
        // 2️⃣ Contact
        // -----------------------------
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            AccountId = acc.Id,
            Email = 'portal@test.com'
        );
        insert con;

        // -----------------------------
        // 3️⃣ Portal Profile
        // -----------------------------
        Profile portalProfile = [
            SELECT Id
            FROM Profile
            WHERE UserType IN ('CSPLitePortal','CustomerSuccess','PowerCustomerSuccess')
            LIMIT 1
        ];

        // -----------------------------
        // 4️⃣ Portal User
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

        // -----------------------------
        // 5️⃣ Required Opportunity
        // -----------------------------
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
            Event_Date__c = Date.today().addDays(30),
            AccountId = acc.Id,
            Occasion__c = 'Corporate Event'
        );
        insert opp;

        // -----------------------------
        // 6️⃣ Quote (Required for Invoice)
        // -----------------------------
        Quote qt = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Status = 'Accepted'
        );
        insert qt;

        // -----------------------------
        // 7️⃣ Create Invoices
        // -----------------------------

        // Unpaid
        Xero_Invoice__c inv1 = new Xero_Invoice__c(
            Account__c = acc.Id,
            Quote__c = qt.Id,
            Xero_Invoice_Number__c = 'INV-001',
            Invoice_Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(10),
            Total_Amount__c = 1000,
            Amount_Due__c = 1000,
            Invoice_Status__c = 'Submitted',
            Payment_Status__c = 'Unpaid'
        );
        insert inv1;

        // Partially Paid
        Xero_Invoice__c inv2 = new Xero_Invoice__c(
            Account__c = acc.Id,
            Quote__c = qt.Id,
            Xero_Invoice_Number__c = 'INV-002',
            Invoice_Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(15),
            Total_Amount__c = 2000,
            Amount_Due__c = 500,
            Invoice_Status__c = 'Submitted',
            Payment_Status__c = 'Partially Paid'
        );
        insert inv2;

        // Fully Paid (Should NOT count)
        Xero_Invoice__c inv3 = new Xero_Invoice__c(
            Account__c = acc.Id,
            Quote__c = qt.Id,
            Xero_Invoice_Number__c = 'INV-003',
            Invoice_Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(20),
            Total_Amount__c = 1500,
            Amount_Due__c = 0,
            Invoice_Status__c = 'Submitted',
            Payment_Status__c = 'Paid'
        );
        insert inv3;

        // -------------------------------------------------
        // 🔐 Execute as Portal User
        // -------------------------------------------------
        System.runAs(portalUser) {

            Test.startTest();

            MaisonOutstandingBalanceService.OutstandingSummaryDTO dto =
                MaisonOutstandingBalanceService.getOutstandingSummary();

            Test.stopTest();

            // Should include only inv1 + inv2
            System.assertEquals(2, dto.invoiceCount);
            System.assertEquals(1500, dto.totalOutstanding);
        }
    }

    // ---------------------------------------
    // Edge Case: User without Contact
    // ---------------------------------------
    @IsTest
    static void testNoContactUser() {

        Test.startTest();

        MaisonOutstandingBalanceService.OutstandingSummaryDTO dto =
            MaisonOutstandingBalanceService.getOutstandingSummary();

        Test.stopTest();

        System.assertEquals(0, dto.invoiceCount);
        System.assertEquals(0, dto.totalOutstanding);
    }
}