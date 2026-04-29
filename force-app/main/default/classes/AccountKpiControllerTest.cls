@IsTest
private class AccountKpiControllerTest {

    @IsTest
    static void testGetAccountKpis() {

        // --------------------------
        // 1. Create Opportunity (Sydney Bookings)
        // --------------------------
        Id rtId = Schema.SObjectType.Opportunity
            .getRecordTypeInfosByName()
            .get('Sydney Bookings')
            .getRecordTypeId();

        Date eventDay = Date.today().addDays(10);

        Opportunity opp = new Opportunity(
            RecordTypeId = rtId,
            Name = 'Booking - Test',

            First_Name__c = 'John',
            Last_Name__c  = 'Doe',
            Phone_Number__c = '9876543210',
            Email_Address__c = 'john@test.com',

            Personal_or_Corporate_Event__c = 'Personal Event',
            Occasion__c = 'Annual Party',
            Event_Date__c = eventDay,
            Event_Type__c = 'Standing Event/ Cocktail Party',
            Number_of_Guests__c = 50,
            Number_of_Staff_Required__c = 5,

            Guest_arrival_time__c = DateTime.newInstance(
                eventDay.year(), eventDay.month(), eventDay.day(), 18, 0, 0
            ),
            Guest_departure_time__c = DateTime.newInstance(
                eventDay.year(), eventDay.month(), eventDay.day(), 23, 0, 0
            ),

            Venue_Address__c = 'Sydney Opera House',
            Uniform_Required__c = 'Black Shirt'
        );
        insert opp;

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

        // --------------------------
        // 3. Create Quote
        // --------------------------
        Quote qt = new Quote(
            Name = 'Quote - Test',
            OpportunityId = opp.Id,
            Status = 'Sent'
        );
        insert qt;

        // --------------------------
        // 3A. Pricebook Setup
        // --------------------------
        Id stdPBId = Test.getStandardPricebookId();

        Pricebook2 stdPB = new Pricebook2(
            Id = stdPBId,
            IsActive = true
        );
        update stdPB;

        qt.Pricebook2Id = stdPBId;
        update qt;

        // --------------------------
        // 3B. Products & Pricebook Entries
        // --------------------------
        Product2 p1 = new Product2(Name = 'Service A', IsActive = true);
        Product2 p2 = new Product2(Name = 'Service B', IsActive = true);
        insert new List<Product2>{ p1, p2 };

        PricebookEntry pbe1 = new PricebookEntry(
            Product2Id = p1.Id,
            Pricebook2Id = stdPBId,
            UnitPrice = 1000,
            IsActive = true
        );
        PricebookEntry pbe2 = new PricebookEntry(
            Product2Id = p2.Id,
            Pricebook2Id = stdPBId,
            UnitPrice = 2000,
            IsActive = true
        );
        insert new List<PricebookEntry>{ pbe1, pbe2 };

        // --------------------------
        // 3C. Quote Line Items
        // --------------------------
        QuoteLineItem qli1 = new QuoteLineItem(
            QuoteId = qt.Id,
            PricebookEntryId = pbe1.Id,
            Quantity = 1,
            UnitPrice = 1000
        );
        QuoteLineItem qli2 = new QuoteLineItem(
            QuoteId = qt.Id,
            PricebookEntryId = pbe2.Id,
            Quantity = 1,
            UnitPrice = 2000
        );
        insert new List<QuoteLineItem>{ qli1, qli2 };

        // --------------------------
        // 3D. Quote Accepted
        // --------------------------
        qt.Status = 'Accepted';
        update qt;

        // --------------------------
        // 4. Create Invoice → simulate Zapier
        // --------------------------
        Xero_Invoice__c inv1 = new Xero_Invoice__c(
            Account__c = accId,
            Quote__c = qt.Id,

            Xero_Invoice_Number__c = 'INV-001',
            Invoice_Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(7),
            Total_Amount__c = 3000,

            Invoice_Status__c = 'Draft',
            Payment_Status__c = 'Unpaid',

            Amount_Due__c = 3000
        );
        insert inv1;

        // Simulate payment
        inv1.Amount_Due__c = 0;
        inv1.Amount_Paid__c = 3000;
        inv1.Payment_Status__c = 'Paid';
        inv1.Invoice_Status__c = 'Paid';
        update inv1;

        // --------------------------
        // 4B. Get Order created by Flow
        // --------------------------
        Order orderFromFlow = [
            SELECT Id, AccountId, Status, Order_Total_Amount__c, EffectiveDate
            FROM Order
            WHERE Xero_Invoice__c = :inv1.Id
            LIMIT 1
        ];

        System.debug('Order created by Flow: ' + orderFromFlow);

        // --------------------------
        // 5. Run KPI Method
        // --------------------------
        Test.startTest();
        AccountKpiController.KpiWrapper result =
            AccountKpiController.getAccountKpis(accId);
        Test.stopTest();

        // --------------------------
        // 6. Assertions
        // --------------------------
        System.assertEquals(1, result.totalEnquiries);
        System.assertEquals(1, result.totalOrders);
        System.assertEquals(3000, result.totalRevenue);
        System.assertEquals(0, result.totalInvoiceDue);
    }
}