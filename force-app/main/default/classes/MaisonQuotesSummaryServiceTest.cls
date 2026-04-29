@IsTest
private class MaisonQuotesSummaryServiceTest {

    @IsTest
    static void testQuoteSummary() {

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
        // 6️⃣ Create Quotes
        // -----------------------------

        // Pending (Sent)
        Quote q1 = new Quote(
            Name = 'Quote 1',
            OpportunityId = opp.Id,
            Status = 'Sent'
        );
        insert q1;

        // Pending (Viewed)
        Quote q2 = new Quote(
            Name = 'Quote 2',
            OpportunityId = opp.Id,
            Status = 'Viewed'
        );
        insert q2;

        // Accepted
        Quote q3 = new Quote(
            Name = 'Quote 3',
            OpportunityId = opp.Id,
            Status = 'Accepted'
        );
        insert q3;

        // -------------------------------------------------
        // 🔐 Execute as Portal User
        // -------------------------------------------------
        System.runAs(portalUser) {

            Test.startTest();

            MaisonQuotesSummaryService.QuoteSummaryDTO summary =
                MaisonQuotesSummaryService.getQuoteSummary();

            Test.stopTest();

            // ---------------- Assertions ----------------

            System.assertEquals(3, summary.totalQuotes);
            System.assertEquals(2, summary.pendingReview);  // Sent + Viewed
            System.assertEquals(1, summary.accepted);
            System.assertEquals(0, summary.totalValue); 
            // Will be 0 if Total_Price_Including_Tax__c is formula & null in test
        }
    }

    // -----------------------------
    // Edge Case: No Contact
    // -----------------------------
    @IsTest
    static void testNoContactUser() {

        Test.startTest();

        MaisonQuotesSummaryService.QuoteSummaryDTO summary =
            MaisonQuotesSummaryService.getQuoteSummary();

        Test.stopTest();

        System.assertEquals(null, summary.totalQuotes);
    }
}