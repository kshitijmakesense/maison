public with sharing class OrderDashboardController {

    /* WRAPPER */
    public class OrderWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String orderName;

        // Enquiry / Opportunity fields
        @AuraEnabled public String enquiryName;
        @AuraEnabled public String recordType;
        @AuraEnabled public Date eventDate;
        @AuraEnabled public String venue;
        @AuraEnabled public Decimal guests;
        @AuraEnabled public String startTimeFormatted;
        @AuraEnabled public String endTimeFormatted;

        // Order fields
        @AuraEnabled public String status;
        @AuraEnabled public Decimal totalAmount;

        // Services
        @AuraEnabled public String serviceList;
    }

    /* --- FORMAT TIME --- */
    private static String formatDateTime(Datetime dt) {
        if (dt == null) return '';
        Time t = dt.time();

        String hh = t.hour() < 10 ? '0' + t.hour() : '' + t.hour();
        String mm = t.minute() < 10 ? '0' + t.minute() : '' + t.minute();
        return hh + ':' + mm;
    }

    /* --- MAIN QUERY --- */
    @AuraEnabled(cacheable=true)
    public static List<OrderWrapper> getOrders(
        Id accountId,
        String status,
        Date startDate,
        Date endDate,
        String searchText,
        String service
    ) {
        if (accountId == null) return new List<OrderWrapper>();

        // Pull Order + related Opportunity (Enquiry)
        List<Order> orders = [
            SELECT 
                Id,
                Name,
                Status,
                Order_Total_Amount__c,
                Event_Date__c,

                /* related enquiry / booking */
                Opportunity.Name,
                Opportunity.Venue_Address__c,
                Opportunity.Number_of_Guests__c,
                Opportunity.RecordType.Name,
                Opportunity.Guest_arrival_time__c,
                Opportunity.Guest_departure_time__c,
                Opportunity.AccountId

            FROM Order
            WHERE Opportunity.AccountId = :accountId
            ORDER BY Event_Date__c DESC, CreatedDate DESC
        ];

        List<Order> filtered = new List<Order>();

        /* --- FILTERS --- */
        for (Order o : orders) {
            Boolean include = true;

            if (status != null && status != '' && o.Status != status)
                include = false;

            if (include && startDate != null &&
                (o.Event_Date__c == null || o.Event_Date__c < startDate))
                include = false;

            if (include && endDate != null &&
                (o.Event_Date__c == null || o.Event_Date__c > endDate))
                include = false;

            if (include) filtered.add(o);
        }

        /* --- SERVICE LIST FROM ORDER LINE ITEMS --- */
        Map<Id, List<String>> servicesByOrder = new Map<Id, List<String>>();

        if (!filtered.isEmpty()) {
            List<Order_Line_Item__c> lines = [
                SELECT Booking_Order__c, Name
                FROM Order_Line_Item__c
                WHERE Booking_Order__c IN :filtered
            ];

            for (Order_Line_Item__c line : lines) {
                if (!servicesByOrder.containsKey(line.Booking_Order__c)) {
                    servicesByOrder.put(line.Booking_Order__c, new List<String>());
                }
                servicesByOrder.get(line.Booking_Order__c).add(line.Name);
            }
        }

        /* --- BUILD WRAPPER LIST --- */
        List<OrderWrapper> result = new List<OrderWrapper>();

        for (Order o : filtered) {
            List<String> services = servicesByOrder.containsKey(o.Id)
                ? servicesByOrder.get(o.Id)
                : new List<String>();

            String serviceString = String.join(services, ', ');

            // Service filter
            if (service != null && service != '' && !services.contains(service))
                continue;

            // Search filter
            if (searchText != null && searchText != '') {
                String s = searchText.toLowerCase();
                Boolean matches =
                    (o.Name != null && o.Name.toLowerCase().contains(s)) ||
                    (o.Opportunity.Name != null && o.Opportunity.Name.toLowerCase().contains(s)) ||
                    serviceString.toLowerCase().contains(s);

                if (!matches) continue;
            }

            /* --- FILL WRAPPER --- */
            OrderWrapper w = new OrderWrapper();
            w.id = o.Id;
            w.orderName = o.Name;

            w.enquiryName = o.Opportunity.Name;
            w.recordType = o.Opportunity.RecordType.Name;
            w.eventDate = o.Event_Date__c;
            w.venue = o.Opportunity.Venue_Address__c;
            w.guests = o.Opportunity.Number_of_Guests__c;
            w.startTimeFormatted = formatDateTime(o.Opportunity.Guest_arrival_time__c);
            w.endTimeFormatted = formatDateTime(o.Opportunity.Guest_departure_time__c);

            w.status = o.Status;
            w.totalAmount = o.Order_Total_Amount__c;
            w.serviceList = serviceString;

            result.add(w);
        }

        return result;
    }

    /* --- SERVICE FILTER OPTIONS --- */
    @AuraEnabled(cacheable=true)
    public static List<String> getServiceFilterOptions(Id accountId) {
        if (accountId == null) return new List<String>();

        List<String> result = new List<String>();

        for (AggregateResult ar : [
            SELECT Name name
            FROM Order_Line_Item__c
            WHERE Booking_Order__r.Opportunity.AccountId = :accountId
            GROUP BY Name
            ORDER BY Name
        ]) {
            result.add((String) ar.get('name'));
        }

        return result;
    }
}