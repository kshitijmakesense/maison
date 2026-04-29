@IsTest
private class MaisonRecentInvoicesServiceTest {

    @IsTest
    static void testRecentInvoicesAndSummary() {

        /* ------------------------------------
         * 1️⃣ Create Account + Contact
         * ------------------------------------ */
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Portal',
            Email = 'portal@test.com',
            AccountId = acc.Id
        );
        insert con;

        /* ------------------------------------
         * 2️⃣ Create Portal User
         * ------------------------------------ */
        Profile portalProfile = [
            SELECT Id
            FROM Profile
            WHERE UserType IN ('CSPLitePortal','CustomerSuccess','PowerCustomerSuccess')
            LIMIT 1
        ];

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

        /* ------------------------------------
         * 3️⃣ Create Opportunity + Quote
         * ------------------------------------ */
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(5),
            AccountId = acc.Id,
             Event_Date__c = Date.today().addDays(10)   
        );
        insert opp;

        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Status = 'Accepted'
        );
        insert q;

        /* ------------------------------------
         * 4️⃣ Create Invoices
         * ------------------------------------ */

        // 🔹 Case 1 — Unpaid + Payment URL → showPay = true
        Xero_Invoice__c inv1 = new Xero_Invoice__c(
            Account__c = acc.Id,
            Quote__c = q.Id,
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

        // 🔹 Case 2 — Unpaid + No Payment URL → showPending = true
        Xero_Invoice__c inv2 = new Xero_Invoice__c(
            Account__c = acc.Id,
            Quote__c = q.Id,
            Xero_Invoice_Number__c = 'INV-002',
            Invoice_Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(5),
            Total_Amount__c = 500,
            Invoice_Status__c = 'Submitted',
            Payment_Status__c = 'Unpaid',
            Amount_Due__c = 500
        );
        insert inv2;

        // 🔹 Case 3 — Paid → no buttons
        Xero_Invoice__c inv3 = new Xero_Invoice__c(
            Account__c = acc.Id,
            Quote__c = q.Id,
            Xero_Invoice_Number__c = 'INV-003',
            Invoice_Date__c = Date.today(),
            Due_Date__c = Date.today(),
            Total_Amount__c = 750,
            Invoice_Status__c = 'Submitted',
            Payment_Status__c = 'Paid',
            Amount_Due__c = 0,
            Last_Payment_Date__c = Date.today()
        );
        insert inv3;

        /* ------------------------------------
         * 5️⃣ Execute as Portal User
         * ------------------------------------ */
        System.runAs(portalUser) {

            Test.startTest();

            List<MaisonRecentInvoicesService.InvoiceDTO> invoices =
                MaisonRecentInvoicesService.getRecentInvoices();

            MaisonRecentInvoicesService.InvoiceSummaryDTO summary =
                MaisonRecentInvoicesService.getInvoiceSummary();

            Test.stopTest();

            System.assertEquals(3, invoices.size());

            Boolean foundPay = false;
            Boolean foundPending = false;
            Boolean foundPaid = false;

            for (MaisonRecentInvoicesService.InvoiceDTO dto : invoices) {

                if (dto.invoiceNumber == 'INV-001') {
                    foundPay = true;
                    System.assertEquals(true, dto.showPay);
                    System.assertEquals(false, dto.showPending);
                }

                if (dto.invoiceNumber == 'INV-002') {
                    foundPending = true;
                    System.assertEquals(false, dto.showPay);
                    System.assertEquals(true, dto.showPending);
                }

                if (dto.invoiceNumber == 'INV-003') {
                    foundPaid = true;
                    System.assertEquals(false, dto.showPay);
                    System.assertEquals(false, dto.showPending);
                }
            }

            System.assert(foundPay);
            System.assert(foundPending);
            System.assert(foundPaid);

            // 🔹 Summary assertions
            System.assertEquals(1500, summary.totalOutstanding);
            System.assertEquals(2, summary.dueCount);
        }
    }

    /* ------------------------------------
     * 6️⃣ User without Contact
     * ------------------------------------ */
    @IsTest
    static void testUserWithoutContact() {

        Test.startTest();

        List<MaisonRecentInvoicesService.InvoiceDTO> invoices =
            MaisonRecentInvoicesService.getRecentInvoices();

        MaisonRecentInvoicesService.InvoiceSummaryDTO summary =
            MaisonRecentInvoicesService.getInvoiceSummary();

        Test.stopTest();

        System.assertEquals(0, invoices.size());
        System.assertEquals(0, summary.totalOutstanding);
        System.assertEquals(0, summary.dueCount);
    }
}