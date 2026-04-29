@IsTest
private class MaisonAllQuotesServiceTest {

    @IsTest
    static void testGetAllQuotesAndCount() {

        // -------------------------------
        // 1️⃣ Create Account
        // -------------------------------
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // -------------------------------
        // 2️⃣ Create Contact
        // -------------------------------
        Contact con = new Contact(
            FirstName = 'Portal',
            LastName = 'User',
            Email = 'portal@test.com',
            AccountId = acc.Id
        );
        insert con;

        // -------------------------------
        // 3️⃣ Portal Profile
        // -------------------------------
        Profile portalProfile = [
            SELECT Id
            FROM Profile
            WHERE UserType IN ('CSPLitePortal','CustomerSuccess','PowerCustomerSuccess')
            LIMIT 1
        ];

        // -------------------------------
        // 4️⃣ Portal User
        // -------------------------------
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

        // -------------------------------
        // 5️⃣ Opportunity (REQUIRED FIELD SAFE)
        // -------------------------------
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(5),
            AccountId = acc.Id,
            Event_Date__c = Date.today().addDays(10),  // REQUIRED
            Venue_Address__c = 'Sydney, Australia',
            Occasion__c = 'Wedding Event'
        );
        insert opp;

        // -------------------------------
        // 6️⃣ Quotes
        // -------------------------------

        // Accepted → with payment link
       Quote q1 = new Quote(
    Name = 'Quote 1',
    OpportunityId = opp.Id,   // 🔑 This is enough
    Status = 'Accepted',
    ExpirationDate = Date.today().addDays(7),
    Quotient_Quote_Number__c = 'Q-001',
    Quotient_Quote_URL__c = 'https://quote1.com'
);
insert q1;


        // Accepted → draft (no payment link)
        Quote q2 = new Quote(
            Name = 'Quote 2',
            OpportunityId = opp.Id,
          
            Status = 'Accepted',
            ExpirationDate = Date.today().addDays(10),
             Quotient_Quote_Number__c = 'Q-002'
        );
        insert q2;

        // Sent (active count)
        Quote q3 = new Quote(
            Name = 'Quote 3',
            OpportunityId = opp.Id,
             Status = 'Sent',
            ExpirationDate = Date.today().addDays(12)
        );
        insert q3;

        // -------------------------------
        // 7️⃣ Xero Invoices
        // -------------------------------

        // For q1 → showPay
        Xero_Invoice__c inv1 = new Xero_Invoice__c(
            Account__c = acc.Id,
            Quote__c = q1.Id,
              Xero_Invoice_Number__c = 'INV-001',
            Invoice_Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(7),
            Total_Amount__c = 1000,
            Invoice_Status__c = 'Submitted',
            Payment_Status__c = 'Unpaid',
            Payment_URL__c = 'https://xero.com/pay1'
        );
        insert inv1;

        // For q2 → showPending
        Xero_Invoice__c inv2 = new Xero_Invoice__c(
            Account__c = acc.Id,
            Quote__c = q2.Id,
              Xero_Invoice_Number__c = 'INV-002',
            Invoice_Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(7),
            Total_Amount__c = 2000,
            Invoice_Status__c = 'Submitted',
            Payment_Status__c = 'Unpaid'
            // No Payment_URL__c
        );
        insert inv2;

        // -------------------------------
        // 🔐 RUN AS PORTAL USER
        // -------------------------------
        System.runAs(portalUser) {

            Test.startTest();

            MaisonAllQuotesService.QuotePageResult result =
                MaisonAllQuotesService.getAllQuotes(10, 1);

            Integer count =
                MaisonAllQuotesService.getTotalQuoteCount();

            Test.stopTest();

            // ---------------------------------
            // Assertions
            // ---------------------------------

            System.assertEquals(3, result.totalCount);
            System.assertEquals(3, result.records.size());
            System.assertEquals(3, count);

            Boolean foundPay = false;
            Boolean foundPending = false;

            for (MaisonAllQuotesService.QuoteDTO dto : result.records) {

                if (dto.quoteNumber == 'Q-001') {
                    System.assertEquals(true, dto.showPay);
                    System.assertEquals('https://xero.com/pay1', dto.xeroUrl);
                    foundPay = true;
                }

                if (dto.quoteNumber == 'Q-002') {
                    System.assertEquals(true, dto.showPending);
                    foundPending = true;
                }
            }

            System.assertEquals(true, foundPay);
            System.assertEquals(true, foundPending);
        }
    }

    // -------------------------------------------------------
    // 🧪 Test user without contact
    // -------------------------------------------------------
    @IsTest
    static void testUserWithoutContact() {

        Test.startTest();

        MaisonAllQuotesService.QuotePageResult result =
            MaisonAllQuotesService.getAllQuotes(10, 1);

        Integer count =
            MaisonAllQuotesService.getTotalQuoteCount();

        Test.stopTest();

        System.assertEquals(0, result.records.size());
        System.assertEquals(0, result.totalCount);
        System.assertEquals(0, count);
    }
}