@IsTest
private class MaisonDashboardServiceTest {

    @IsTest
    static void testGetDashboardData() {

        // 1️⃣ Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // 2️⃣ Create Contact
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            AccountId = acc.Id,
            Email = 'portal@test.com'
        );
        insert con;

        // 3️⃣ Get Portal Profile
        Profile portalProfile = [
            SELECT Id
            FROM Profile
            WHERE UserType IN ('CSPLitePortal','CustomerSuccess','PowerCustomerSuccess')
            LIMIT 1
        ];

        // 4️⃣ Create Portal User
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

        // ------------------------------------------------
        // 🔥 CREATE ALL DATA IN SYSTEM CONTEXT (IMPORTANT)
        // ------------------------------------------------

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
            AccountId = acc.Id
        );
        insert opp;

        Quote qt = new Quote(
            Name = 'Quote Test',
            OpportunityId = opp.Id,
            Status = 'Sent'
        );
        insert qt;

        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Event_Date__c = Date.today().addDays(3)
        );
        insert ord;

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

        // ------------------------------------------------
        // 🔐 ONLY CALL SERVICE AS PORTAL USER
        // ------------------------------------------------

        System.runAs(portalUser) {

            Test.startTest();
            Map<String, Object> result =
                MaisonDashboardService.getDashboardData();
            Test.stopTest();

            System.assertEquals(1, result.get('activeQuotes'));
            System.assertEquals(1, result.get('upcomingBookings'));
            System.assertEquals(1, result.get('pendingInvoices'));
            System.assertEquals(2500, result.get('totalOutstanding'));
        }
    }
}