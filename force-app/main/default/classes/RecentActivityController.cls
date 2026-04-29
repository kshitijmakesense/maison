public with sharing class RecentActivityController {

    @AuraEnabled
    public static List<TimelineWrapper> getRecentActivities(Id accountId) {
        List<TimelineWrapper> timeline = new List<TimelineWrapper>();
        Datetime oneWeekAgo = Datetime.now().addDays(-7);

        // 1️⃣ Enquiries (Opportunities)
for (Opportunity enq : [
    SELECT Id, Name, StageName, CreatedDate, AccountId, SystemModstamp
    FROM Opportunity
    WHERE AccountId = :accountId
    AND SystemModstamp >= :oneWeekAgo
    ORDER BY SystemModstamp DESC
]) {

    // 🔍 Fetch Active Quote (safe query)
    List<Quote> activeQuoteList = [
        SELECT Id, Total_Price_Including_Tax__c
        FROM Quote
        WHERE OpportunityId = :enq.Id
        AND Active__c = TRUE
        LIMIT 1
    ];

    Quote activeQuote = activeQuoteList.isEmpty() ? null : activeQuoteList[0];

    // 💰 Calculate amount
    Decimal totalAmount = null;
    if (activeQuote != null) {
        totalAmount = activeQuote.Total_Price_Including_Tax__c;
    }

    timeline.add(new TimelineWrapper(
        enq.Id,
        enq.Name,
        'Enquiry',
        enq.SystemModstamp,
        enq.StageName,
        null,
        totalAmount
    ));
}


        // 2️⃣ Orders (Events)
        for (Order ord : [
            SELECT Id, Opportunity.Name, Event_Date__c, Status, Order_Total_Amount__c, SystemModstamp,
                   (SELECT Id, Name, Quantity__c FROM Order_Line_Items__r)
            FROM Order
            WHERE AccountId = :accountId
            AND SystemModstamp >= :oneWeekAgo
            ORDER BY SystemModstamp DESC
        ]) {
            String lineItems = '';

            if (ord.Order_Line_Items__r != null && !ord.Order_Line_Items__r.isEmpty()) {
                List<String> items = new List<String>();
                for (Order_Line_Item__c oli : ord.Order_Line_Items__r) {
                    String item = oli.Name;
                    if (oli.Quantity__c != null) {
                        item += ' (' + oli.Quantity__c.intValue() + ')';
                    }
                    items.add(item);
                }
                lineItems = String.join(items, ', ');
            }

            timeline.add(new TimelineWrapper(
                ord.Id,
                ord.Opportunity.Name,
                'Event Bookings',
                ord.SystemModstamp,
                ord.Status,
                lineItems,
                ord.Order_Total_Amount__c
            ));
        }

        // 3️⃣ Quotes
        for (Quote q : [
            SELECT Id, Name, Status, CreatedDate, SystemModstamp,
                   (SELECT Id, Product2.Name, Quantity FROM QuoteLineItems),
                   Total_Price_Including_Tax__c
            FROM Quote
            WHERE AccountId = :accountId
            AND SystemModstamp >= :oneWeekAgo
            ORDER BY SystemModstamp DESC
        ]) {
            String lineItems = '';

            if (q.QuoteLineItems != null && !q.QuoteLineItems.isEmpty()) {
                List<String> items = new List<String>();
                for (QuoteLineItem qli : q.QuoteLineItems) {
                    String item = (qli.Product2 != null) ? qli.Product2.Name : 'Item';
                    if (qli.Quantity != null) {
                        item += ' (' + qli.Quantity.intValue() + ')';
                    }
                    items.add(item);
                }
                lineItems = String.join(items, ', ');
            }

            timeline.add(new TimelineWrapper(
                q.Id,
                q.Name,
                'Quote',
                q.SystemModstamp,
                q.Status,
                lineItems,
                q.Total_Price_Including_Tax__c
            ));
        }

        // 4️⃣ Invoices
        for (Xero_Invoice__c inv : [
            SELECT Id, Xero_Invoice_Number__c, Name, Invoice_Status__c, Invoice_Date__c, Amount_Due__c, SystemModstamp
            FROM Xero_Invoice__c
            WHERE Account__c = :accountId
            AND SystemModstamp >= :oneWeekAgo
            ORDER BY SystemModstamp DESC
        ]) {
            timeline.add(new TimelineWrapper(
                inv.Id,
                inv.Xero_Invoice_Number__c,
                'Invoice',
                inv.SystemModstamp,
                inv.Invoice_Status__c,
                null,
                inv.Amount_Due__c
            ));
        }

        // Sort descending by activity date
        timeline.sort(new ActivityDateComparator());

        // Return only top 15
        Integer limitCount = Math.min(15, timeline.size());
        List<TimelineWrapper> top15 = new List<TimelineWrapper>();
        for (Integer i = 0; i < limitCount; i++) {
            top15.add(timeline[i]);
        }

        return top15;
    }

    // Wrapper class
    public class TimelineWrapper {
        @AuraEnabled public Id Id { get; set; }
        @AuraEnabled public String Name { get; set; }
        @AuraEnabled public String Type { get; set; }
        @AuraEnabled public Datetime ActivityDate { get; set; }
        @AuraEnabled public String Status { get; set; }
        @AuraEnabled public String LineItems { get; set; }
        @AuraEnabled public Decimal Amount { get; set; }

        public TimelineWrapper(
            Id id,
            String name,
            String type,
            Datetime actDate,
            String status,
            String lineItems,
            Decimal amount
        ) {
            this.Id = id;
            this.Name = name;
            this.Type = type;
            this.ActivityDate = actDate;
            this.Status = status;
            this.LineItems = lineItems;
            this.Amount = amount;
        }
    }

    // Comparator for sorting
    public class ActivityDateComparator implements Comparator<TimelineWrapper> {
        public Integer compare(TimelineWrapper a, TimelineWrapper b) {
            if (a.ActivityDate == b.ActivityDate) return 0;
            if (a.ActivityDate == null) return 1;
            if (b.ActivityDate == null) return -1;
            return (a.ActivityDate > b.ActivityDate) ? -1 : 1;
        }
    }
}