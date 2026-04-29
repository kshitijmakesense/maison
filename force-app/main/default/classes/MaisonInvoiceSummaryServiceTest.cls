@IsTest
private class MaisonInvoiceSummaryServiceTest {

    @IsTest
    static void testInvoiceSummary() {

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
        // 5️⃣ Required Opportunity (for org validation)
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
            AccountId = acc.Id
        );
        insert opp;

        // Create Quote
Quote qt = new Quote(
    Name = 'Test Quote',
    OpportunityId = opp.Id,
    Status = 'Sent'
);
insert qt;

        // -----------------------------
        // 6️⃣ Create Invoices
        // -----------------------------

        // 🔹 Unpaid Invoice
        Xero_Invoice__c inv1 = new Xero_Invoice__c(
            Account__c = acc.Id,
             Quote__c = qt.Id,   // ✅ REQUIRED
            Xero_Invoice_Number__c = 'INV-001',
            Invoice_Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(7),
            Total_Amount__c = 1000,
            Invoice_Status__c = 'Submitted',
            Payment_Status__c = 'Unpaid',
            Amount_Due__c = 1000
        );
        insert inv1;

        // 🔹 Paid This Year
        Xero_Invoice__c inv2 = new Xero_Invoice__c(
            Account__c = acc.Id,
             Quote__c = qt.Id,   // ✅ REQUIRED
            Xero_Invoice_Number__c = 'INV-002',
            Invoice_Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(5),
            Total_Amount__c = 2000,
            Invoice_Status__c = 'Paid',
            Payment_Status__c = 'Paid',
            Last_Payment_Date__c = Date.today(),
            Amount_Due__c = 0
        );
        insert inv2;

        // 🔹 Paid Previous Year (should NOT count in paidThisYear)
        Xero_Invoice__c inv3 = new Xero_Invoice__c(
            Account__c = acc.Id,
             Quote__c = qt.Id,   // ✅ REQUIRED
            Xero_Invoice_Number__c = 'INV-003',
            Invoice_Date__c = Date.today().addYears(-1),
            Due_Date__c = Date.today().addYears(-1).addDays(7),
            Total_Amount__c = 3000,
            Invoice_Status__c = 'Paid',
            Payment_Status__c = 'Paid',
            Last_Payment_Date__c = Date.today().addYears(-1),
            Amount_Due__c = 0
        );
        insert inv3;

        // -------------------------------------------------
        // 🔐 Execute as Portal User
        // -------------------------------------------------
        System.runAs(portalUser) {

            Test.startTest();

            MaisonInvoiceSummaryService.InvoiceSummaryDTO summary =
                MaisonInvoiceSummaryService.getInvoiceSummary();

            Test.stopTest();

            // ---------------- Assertions ----------------

            System.assertEquals(3, summary.totalInvoices);
            System.assertEquals(1, summary.pendingInvoices);
            System.assertEquals(1000, summary.amountDue);
            System.assertEquals(2000, summary.paidThisYear);
        }
    }

    // -----------------------------
    // Edge Case: No Contact User
    // -----------------------------
    @IsTest
    static void testNoContactUser() {

        Test.startTest();

        MaisonInvoiceSummaryService.InvoiceSummaryDTO summary =
            MaisonInvoiceSummaryService.getInvoiceSummary();

        Test.stopTest();

        System.assertEquals(0, summary.totalInvoices);
        System.assertEquals(0, summary.pendingInvoices);
        System.assertEquals(0, summary.amountDue);
        System.assertEquals(0, summary.paidThisYear);
    }
}