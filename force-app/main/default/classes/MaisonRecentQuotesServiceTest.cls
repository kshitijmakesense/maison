@IsTest
private class MaisonRecentQuotesServiceTest {

    @IsTest
    static void testRecentQuotes_AllBranches() {

        // =====================================================
        // 1️⃣ Create Account + Contact
        // =====================================================
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            AccountId = acc.Id,
            Email = 'portal@test.com'
        );
        insert con;

        // =====================================================
        // 2️⃣ Get Portal Profile
        // =====================================================
        Profile portalProfile = [
            SELECT Id
            FROM Profile
            WHERE UserType IN ('CSPLitePortal','CustomerSuccess','PowerCustomerSuccess')
            LIMIT 1
        ];

        // =====================================================
        // 3️⃣ Create Portal User
        // =====================================================
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

        // =====================================================
        // 4️⃣ Create Opportunity
        // =====================================================
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

        // =====================================================
        // CASE 1️⃣ Unpaid + Payment URL → showPay = true
        // =====================================================
        Quote q1 = new Quote(
            Name = 'Quote 1',
            OpportunityId = opp.Id,
            Status = 'Accepted',
            ExpirationDate = Date.today().addDays(7),
            Quotient_Quote_Number__c = 'Q-001',
            Quotient_Quote_URL__c = 'https://quote1.com'
        );
        insert q1;

       Xero_Invoice__c inv1 = new Xero_Invoice__c(
    Account__c = acc.Id,
    Quote__c = q1.Id,
    Xero_Invoice_Number__c = 'INV-001',
    Invoice_Date__c = Date.today(),
    Due_Date__c = Date.today().addDays(7),
    Total_Amount__c = 1000,
    Invoice_Status__c = 'Submitted',
    Payment_Status__c = 'Unpaid',
    Amount_Due__c = 1000,
    Payment_URL__c = 'https://xero.com/pay1'
);
insert inv1;


        // =====================================================
        // CASE 2️⃣ Unpaid + No Payment URL → showPending = true
        // =====================================================
        Quote q2 = new Quote(
            Name = 'Quote 2',
            OpportunityId = opp.Id,
            Status = 'Accepted',
            ExpirationDate = Date.today().addDays(5),
            Quotient_Quote_Number__c = 'Q-002'
        );
        insert q2;

       Xero_Invoice__c inv2 = new Xero_Invoice__c(
    Account__c = acc.Id,
    Quote__c = q2.Id,
    Xero_Invoice_Number__c = 'INV-002',
    Invoice_Date__c = Date.today(),
    Due_Date__c = Date.today().addDays(5),
    Total_Amount__c = 500,
    Invoice_Status__c = 'Submitted',
    Payment_Status__c = 'Unpaid',
    Amount_Due__c = 500
);
insert inv2;


        // =====================================================
        // CASE 3️⃣ Paid → hide both
        // =====================================================
        Quote q3 = new Quote(
            Name = 'Quote 3',
            OpportunityId = opp.Id,
            Status = 'Accepted'
        );
        insert q3;

       Xero_Invoice__c inv3 = new Xero_Invoice__c(
    Account__c = acc.Id,
    Quote__c = q3.Id,
    Xero_Invoice_Number__c = 'INV-003',
    Invoice_Date__c = Date.today(),
    Due_Date__c = Date.today(),
    Total_Amount__c = 750,
    Invoice_Status__c = 'Submitted',
    Payment_Status__c = 'Paid',
    Amount_Due__c = 0
);
insert inv3;


        // =====================================================
        // CASE 4️⃣ Sent + Viewed (for active count)
        // =====================================================
        Quote q4 = new Quote(
            Name = 'Quote 4',
            OpportunityId = opp.Id,
            Status = 'Sent'
        );
        insert q4;

        Quote q5 = new Quote(
            Name = 'Quote 5',
            OpportunityId = opp.Id,
            Status = 'Viewed'
        );
        insert q5;

        // =====================================================
        // EXECUTE AS PORTAL USER
        // =====================================================
        System.runAs(portalUser) {

            Test.startTest();

            List<MaisonRecentQuotesService.QuoteDTO> quotes =
                MaisonRecentQuotesService.getRecentQuotes();

            Integer activeCount =
                MaisonRecentQuotesService.getActiveQuoteCount();

            Test.stopTest();

            System.assert(quotes.size() > 0);
            System.assertEquals(2, activeCount); // Sent + Viewed

            for (MaisonRecentQuotesService.QuoteDTO dto : quotes) {

                // CASE 1
                if (dto.quoteNumber == 'Q-001') {
                    System.assertEquals(true, dto.showPay);
                    System.assertEquals(false, dto.showPending);
                    System.assertEquals('https://xero.com/pay1', dto.xeroUrl);
                }

                // CASE 2
                if (dto.quoteNumber == 'Q-002') {
                    System.assertEquals(false, dto.showPay);
                    System.assertEquals(true, dto.showPending);
                }

                // CASE 3
                if (dto.name == 'Quote 3') {
                    System.assertEquals(false, dto.showPay);
                    System.assertEquals(false, dto.showPending);
                }
            }
        }
    }

    // =====================================================
    // USER WITHOUT CONTACT
    // =====================================================
    @IsTest
    static void testUserWithoutContact() {

        Test.startTest();
        List<MaisonRecentQuotesService.QuoteDTO> quotes =
            MaisonRecentQuotesService.getRecentQuotes();
        Integer count =
            MaisonRecentQuotesService.getActiveQuoteCount();
        Test.stopTest();

        System.assertEquals(0, quotes.size());
        System.assertEquals(0, count);
    }
}