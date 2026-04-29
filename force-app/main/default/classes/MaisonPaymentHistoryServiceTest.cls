@IsTest
private class MaisonPaymentHistoryServiceTest {

    @IsTest
    static void testPaymentHistory() {

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
        // 5️⃣ Opportunity (Required)
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
            Event_Date__c = Date.today().addDays(15),
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
        // 7️⃣ Paid Invoice (Should Return)
        // -----------------------------
        Xero_Invoice__c paidInv = new Xero_Invoice__c(
            Account__c = acc.Id,
            Quote__c = qt.Id,
            Xero_Invoice_Number__c = 'INV-PAID',
            Invoice_Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(10),
            Total_Amount__c = 2000,
            Amount_Paid__c = 2000,
            Invoice_Status__c = 'Submitted',
            Payment_Status__c = 'Paid',
            Last_Payment_Date__c = Date.today()
        );
        insert paidInv;

        // -----------------------------
        // 8️⃣ Partially Paid Invoice (Should Return)
        // -----------------------------
        Xero_Invoice__c partialInv = new Xero_Invoice__c(
            Account__c = acc.Id,
            Quote__c = qt.Id,
            Xero_Invoice_Number__c = 'INV-PARTIAL',
            Invoice_Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(12),
            Total_Amount__c = 3000,
            Amount_Paid__c = 1000,
            Invoice_Status__c = 'Submitted',
            Payment_Status__c = 'Partially Paid',
            Last_Payment_Date__c = Date.today()
        );
        insert partialInv;

        // -----------------------------
        // 9️⃣ Unpaid Invoice (Should NOT Return)
        // -----------------------------
        Xero_Invoice__c unpaidInv = new Xero_Invoice__c(
            Account__c = acc.Id,
            Quote__c = qt.Id,
            Xero_Invoice_Number__c = 'INV-UNPAID',
            Invoice_Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(15),
            Total_Amount__c = 1500,
            Amount_Paid__c = 0,
            Invoice_Status__c = 'Submitted',
            Payment_Status__c = 'Unpaid'
        );
        insert unpaidInv;

        // -------------------------------------------------
        // 🔐 Execute as Portal User
        // -------------------------------------------------
        System.runAs(portalUser) {

            Test.startTest();

            List<MaisonPaymentHistoryService.PaymentDTO> result =
                MaisonPaymentHistoryService.getPaymentHistory();

            Test.stopTest();

            // Should return only 2 (Paid + Partially Paid)
            System.assertEquals(2, result.size());

            // Validate one record
            Boolean foundPaid = false;

            for (MaisonPaymentHistoryService.PaymentDTO dto : result) {

                if (dto.invoiceNumber == 'INV-PAID') {
                    foundPaid = true;
                    System.assertEquals(2000, dto.amount);
                    System.assertEquals('Corporate Event', dto.description);
                    System.assertNotEquals(null, dto.paymentDate);
                }
            }

            System.assertEquals(true, foundPaid);
        }
    }

    // ---------------------------------------
    // Edge Case: User without Contact
    // ---------------------------------------
    @IsTest
    static void testNoContactUser() {

        Test.startTest();

        List<MaisonPaymentHistoryService.PaymentDTO> result =
            MaisonPaymentHistoryService.getPaymentHistory();

        Test.stopTest();

        System.assertEquals(0, result.size());
    }
}