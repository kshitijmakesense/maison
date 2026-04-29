@IsTest
private class CustomQuoteRelatedListControllerTest {

    @IsTest
    static void testGetQuotes() {

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
        // 1A. Re-query Opportunity Contact
        // --------------------------
        Contact createdCon = [
            SELECT Id, AccountId
            FROM Contact
            WHERE Email = :opp.Email_Address__c
            LIMIT 1
        ];

        System.assertNotEquals(null, createdCon,
            'Flow did not auto-create Contact');

        // --------------------------
        // 2. Create Account manually
        // --------------------------
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // --------------------------
        // 3. Map auto-created Contact → Account
        // --------------------------
        createdCon.AccountId = acc.Id;
        update createdCon;

        // --------------------------
        // 4. Map Opportunity → Account
        // --------------------------
        opp.AccountId = acc.Id;
        update opp;

        Id accId = acc.Id;

        // --------------------------
        // 3. Create Quotes (one tied to Opportunity)
        // --------------------------
        Quote quote2 = new Quote(
            Name = 'Quote 2',
            OpportunityId = opp.Id,
            Status = 'Draft'
        );
        insert new List<Quote>{ quote2 };

        // --------------------------
        // 4. Call the Controller
        // --------------------------
        Test.startTest();
        List<Quote> resultByAccount =
            CustomQuoteRelatedListController.getQuotes(acc.Id);

        List<Quote> resultByOpp =
            CustomQuoteRelatedListController.getQuotes(opp.Id);
        Test.stopTest();

        // --------------------------
        // 5. Assertions
        // --------------------------
        System.assertEquals(
            1, resultByAccount.size(),
            'Only one quote should match Account (one via opp)'
        );

        System.assertEquals(
            1, resultByOpp.size(),
            'Only one quote should match Opportunity'
        );
    }
}