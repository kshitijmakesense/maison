@IsTest
private class MaisonAllInvoicesServiceTest {

    @IsTest
    static void testGetAllInvoices() {

        // -----------------------------
        // 1️⃣ Create Account + Contact
        // -----------------------------
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            AccountId = acc.Id,
            Email = 'portal@test.com'
        );
        insert con;

        // -----------------------------
        // 2️⃣ Create Portal User
        // -----------------------------
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

        // -----------------------------
        // 3️⃣ Create Opportunity
        // -----------------------------
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(5),
            AccountId = acc.Id,
            Event_Date__c = Date.today().addDays(10)
        );
        insert opp;

        // -----------------------------
        // 4️⃣ Create Quote
        // -----------------------------
        Quote q = new Quote(
            Name = 'Quote 1',
            OpportunityId = opp.Id,
            Status = 'Accepted',
            ExpirationDate = Date.today().addDays(7),
            Quotient_Quote_Number__c = 'Q-001',
            Quotient_Quote_URL__c = 'https://quote.com'
        );
        insert q;

        // -----------------------------
        // 5️⃣ Create Invoices
        // -----------------------------

        // 🔹 Case 1: Payment link exists → showPay = true
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
            Payment_URL__c = 'https://pay.com/inv1'
        );
        insert inv1;

        // 🔹 Case 2: Unpaid but NO link → showPending = true
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

        // 🔹 Case 3: Paid → no pay button
        Xero_Invoice__c inv3 = new Xero_Invoice__c(
            Account__c = acc.Id,
            Quote__c = q.Id,
            Xero_Invoice_Number__c = 'INV-003',
            Invoice_Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(3),
            Total_Amount__c = 300,
            Invoice_Status__c = 'Submitted',
            Payment_Status__c = 'Paid',
            Amount_Due__c = 0
        );
        insert inv3;

        // -----------------------------
        // 6️⃣ Create Booking (Order)
        // -----------------------------
        Order ord = new Order(
            Name = 'Booking 1',
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            OpportunityId = opp.Id,
            Xero_Invoice__c = inv1.Id
        );
        insert ord;

        // -----------------------------
        // 7️⃣ Run As Portal User
        // -----------------------------
        System.runAs(portalUser) {

            Test.startTest();
            List<MaisonAllInvoicesService.InvoiceDTO> invoices =
                MaisonAllInvoicesService.getAllInvoices();
            Test.stopTest();

            System.assertEquals(3, invoices.size());

            Boolean foundPay = false;
            Boolean foundPending = false;
            Boolean foundPaid = false;

            for (MaisonAllInvoicesService.InvoiceDTO dto : invoices) {

                if (dto.invoiceNumber == 'INV-001') {
                    foundPay = true;
                    System.assertEquals(true, dto.showPay);
                    System.assertEquals('https://pay.com/inv1', dto.xeroUrl);
                }

                if (dto.invoiceNumber == 'INV-002') {
                    foundPending = true;
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
        }
    }

    // ---------------------------------
    // 8️⃣ User without Contact
    // ---------------------------------
    @IsTest
    static void testUserWithoutContact() {

        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(u) {

            Test.startTest();
            List<MaisonAllInvoicesService.InvoiceDTO> invoices =
                MaisonAllInvoicesService.getAllInvoices();
            Test.stopTest();

            System.assertEquals(0, invoices.size());
        }
    }
}