public with sharing class EnquiryDashboardController {

    public class EnquiryWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public Date eventDate;
        @AuraEnabled public String arrivalTimeFormatted;
        @AuraEnabled public String departureTimeFormatted;
        @AuraEnabled public String venue;
        @AuraEnabled public Decimal guests;
        @AuraEnabled public Decimal budget;
        @AuraEnabled public String stage;
        @AuraEnabled public String serviceList;
        @AuraEnabled public String recordTypeName;
        @AuraEnabled public String recordTypeLabel;

    }

    // Time formatting helper
    private static String formatTime(Time t) {
        if (t == null) return '';

        Integer h = t.hour();
        Integer m = t.minute();

        String hh = (h < 10 ? '0' : '') + h;
        String mm = (m < 10 ? '0' : '') + m;

        return hh + ':' + mm;
    }

    @AuraEnabled(cacheable=true)
    public static List<EnquiryWrapper> getEnquiries(
        Id accountId,
        String status,
        Date startDate,
        Date endDate,
        String searchText,
        String service
    ) {
        if (accountId == null) return new List<EnquiryWrapper>();

        List<Opportunity> opps = [
            SELECT Id, Name, Event_Date__c,
                   Guest_arrival_time__c, Guest_departure_time__c,
                   Venue_Address__c, Number_of_Guests__c,
                   Estimated_Budget__c, StageName,
    RecordType.DeveloperName,
    RecordType.Name
            FROM Opportunity
            WHERE AccountId = :accountId
            ORDER BY Event_Date__c DESC
        ];

        List<Opportunity> filtered = new List<Opportunity>();

        for (Opportunity o : opps) {
            Boolean include = true;

            if (status != null && status != '' && o.StageName != status)
                include = false;

            if (include && startDate != null &&
                (o.Event_Date__c == null || o.Event_Date__c < startDate))
                include = false;

            if (include && endDate != null &&
                (o.Event_Date__c == null || o.Event_Date__c > endDate))
                include = false;

            if (include)
                filtered.add(o);
        }

        // Collect services from Quote Line Items
        Map<Id, List<String>> oppServices = new Map<Id, List<String>>();

        if (!filtered.isEmpty()) {
            List<QuoteLineItem> qlis = [
                SELECT Quote.OpportunityId, Product2.Name
                FROM QuoteLineItem
                WHERE Quote.OpportunityId IN :filtered
            ];

            for (QuoteLineItem qli : qlis) {
                Id oppId = qli.Quote.OpportunityId;

                if (!oppServices.containsKey(oppId)) {
                    oppServices.put(oppId, new List<String>());
                }

                oppServices.get(oppId).add(qli.Product2.Name);
            }
        }

        List<EnquiryWrapper> result = new List<EnquiryWrapper>();

        for (Opportunity o : filtered) {
            List<String> services = oppServices.containsKey(o.Id)
                ? oppServices.get(o.Id)
                : new List<String>();

            String serviceString = String.join(services, ', ');

            // Filter by selected service
            if (service != null && service != '' &&
                !services.contains(service))
                continue;

            // Search filter
            if (searchText != null && searchText != '') {
                String s = searchText.toLowerCase();

                Boolean matches =
                    o.Name.toLowerCase().contains(s) ||
                    (o.Venue_Address__c != null &&
                     o.Venue_Address__c.toLowerCase().contains(s)) ||
                    serviceString.toLowerCase().contains(s);

                if (!matches) continue;
            }

            EnquiryWrapper w = new EnquiryWrapper();
            w.id = o.Id;
            w.name = o.Name;
            w.eventDate = o.Event_Date__c;
          w.arrivalTimeFormatted = formatDateTime(o.Guest_arrival_time__c);
w.departureTimeFormatted = formatDateTime(o.Guest_departure_time__c);
   w.venue = o.Venue_Address__c;
            w.guests = o.Number_of_Guests__c;
            w.budget = o.Estimated_Budget__c;
            w.stage = o.StageName;
            w.serviceList = serviceString;
            // ⭐ ADD THIS
w.recordTypeName = o.RecordType.DeveloperName;
w.recordTypeLabel = o.RecordType.Name;


            result.add(w);
        }

        return result;
    }

private static String formatDateTime(Datetime dt) {
    if (dt == null) return '';

    Time t = dt.time();

    Integer h = t.hour();
    Integer m = t.minute();

    String hh = (h < 10 ? '0' : '') + h;
    String mm = (m < 10 ? '0' : '') + m;

    return hh + ':' + mm;
}

    @AuraEnabled(cacheable=true)
    public static List<String> getServiceFilterOptions(Id accountId) {
        if (accountId == null) return new List<String>();

        List<String> output = new List<String>();

        for (AggregateResult ar : [
            SELECT Product2.Name name
            FROM QuoteLineItem
            WHERE Quote.Opportunity.AccountId = :accountId
            GROUP BY Product2.Name
            ORDER BY Product2.Name
        ]) {
            output.add((String)ar.get('name'));
        }

        return output;
    }

    @AuraEnabled(cacheable=true)
public static Opportunity getEnquiryById(Id enquiryId) {
    return [
        SELECT Id, Name, Event_Date__c, Venue_Address__c,
               Number_of_Guests__c, Estimated_Budget__c, Additional_beverages_or_snacks__c, Special_Requests__c, Speciality_Items__c,
               RecordTypeId, Cart_Area__c, Setup_Breakdown__c, Branding_preference__c, Signage_requirement__c, Access_Instructions__c, 
               RecordType.DeveloperName, Guest_arrival_time__c, Coffee_cart_to_be_branded_or_customized__c, Event_Logo_Theme__c,
               RecordType.Name,Occasion__c, Coffee_service_start_time__c, Coffee_service_end_time__c, Beverages_Coffee_Type__c
        FROM Opportunity
        WHERE Id = :enquiryId
        LIMIT 1
    ];
}

@AuraEnabled
public static void updateEnquiry(Map<String, Object> fields) {

     System.debug('USER: ' + UserInfo.getUserName());
    System.debug('FIELDS: ' + fields);
    System.debug('PROFILE: ' + UserInfo.getProfileId());
    // Convert fields from LWC → Opportunity
    Opportunity incoming = (Opportunity) JSON.deserialize(JSON.serialize(fields), Opportunity.class);

    // Get existing Opportunity
    Opportunity existingOpp = [
        SELECT Id, Name, StageName, CloseDate, Amount,
               RecordTypeId, Event_Date__c, Venue_Address__c,
               Number_of_Guests__c, Estimated_Budget__c
        FROM Opportunity
        WHERE Id = :incoming.Id
        LIMIT 1
    ];

    // Apply only changed fields
    existingOpp.Name = incoming.Name;
    existingOpp.Event_Date__c = incoming.Event_Date__c;
    existingOpp.Venue_Address__c = incoming.Venue_Address__c;
    existingOpp.Number_of_Guests__c = incoming.Number_of_Guests__c;
    existingOpp.Estimated_Budget__c = incoming.Estimated_Budget__c;

    update existingOpp;
}

/**
 * Update Enquiry Record dynamically based on record type
 */
@AuraEnabled
public static Map<String, Object> updateEnquiryRecord(String enquiryData, String recordId, String recordTypeName) {
    Map<String, Object> result = new Map<String, Object>();
    
    try {
        Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(enquiryData);

        // Fetch existing record
        Opportunity opp = [
            SELECT Id, RecordTypeId, RecordType.DeveloperName
            FROM Opportunity
            WHERE Id = :recordId
            LIMIT 1
        ];

        // Map common fields
        opp = mapCommonFields(opp, dataMap);

        // Map record-type-specific fields
        if (recordTypeName == 'Sydney_Bookings' ||
            recordTypeName == 'Catering' ||
            recordTypeName == 'Melbourne_Bookings') {
            
            opp = mapStandardLayoutFields(opp, dataMap);

        } else if (recordTypeName == 'Coffee_Cart') {

            opp = mapCoffeeCartFields(opp, dataMap);
        }

        update opp;

        result.put('success', true);
        result.put('recordId', opp.Id);
        result.put('message', 'Enquiry has been updated successfully.');
        
    } catch (Exception e) {
        result.put('success', false);
        result.put('message', 'Failed to update enquiry: ' + e.getMessage());
        throw new AuraHandledException('Error updating enquiry: ' + e.getMessage());
    }

    return result;
}

    /**
     * Map common fields present in all layouts
     */
    private static Opportunity mapCommonFields(Opportunity opp, Map<String, Object> dataMap) {
        // Required fields
        if (dataMap.containsKey('Name')) {
            opp.Name = (String) dataMap.get('Name');
        }
        
        if (dataMap.containsKey('StageName')) {
            opp.StageName = (String) dataMap.get('StageName');
        }
        
        if (dataMap.containsKey('CloseDate')) {
            opp.CloseDate = Date.valueOf((String) dataMap.get('CloseDate'));
        }
        
        // Account
        if (dataMap.containsKey('AccountId') && dataMap.get('AccountId') != null) {
            opp.AccountId = (String) dataMap.get('AccountId');
        }
        
        // Common fields across all layouts
        if (dataMap.containsKey('First_Name__c')) {
            opp.First_Name__c = (String) dataMap.get('First_Name__c');
        }
        
        if (dataMap.containsKey('Last_Name__c')) {
            opp.Last_Name__c = (String) dataMap.get('Last_Name__c');
        }
        
        if (dataMap.containsKey('Phone_Number__c')) {
            opp.Phone_Number__c = (String) dataMap.get('Phone_Number__c');
        }
        
        if (dataMap.containsKey('Email_Address__c')) {
            opp.Email_Address__c = (String) dataMap.get('Email_Address__c');
        }
        
        if (dataMap.containsKey('Event_Date__c')) {
            opp.Event_Date__c = Date.valueOf((String) dataMap.get('Event_Date__c'));
        }
        
        if (dataMap.containsKey('Event_Time__c') && String.isNotBlank((String) dataMap.get('Event_Time__c'))) {
            String timeStr = (String) dataMap.get('Event_Time__c');
            List<String> timeParts = timeStr.split(':');
            opp.Event_Time__c = Time.newInstance(
                Integer.valueOf(timeParts[0]), 
                Integer.valueOf(timeParts[1]), 
                0, 
                0
            );
        }
        
       object val = dataMap.get('Number_of_Guests__c');
if (val != null && String.valueOf(val).trim() != '') {
    opp.Number_of_Guests__c = Decimal.valueOf(String.valueOf(val));
}

        
       object val1 = dataMap.get('Estimated_Budget__c');
if (val1 != null && String.valueOf(val1).trim() != '') {
    opp.Estimated_Budget__c = Decimal.valueOf(String.valueOf(val1));
}

        
        if (dataMap.containsKey('Venue_Address__c')) {
            opp.Venue_Address__c = (String) dataMap.get('Venue_Address__c');
        }
        
        if (dataMap.containsKey('Event_Type__c')) {
            opp.Event_Type__c = (String) dataMap.get('Event_Type__c');
        }
        
        return opp;
    }

  /**
     * Map fields specific to Coffee Cart Layout
     */
    private static Opportunity mapCoffeeCartFields(Opportunity opp, Map<String, Object> dataMap) {
        if (dataMap.containsKey('Event_Location__c')) {
            opp.Event_Location__c = (String) dataMap.get('Event_Location__c');
        }
        
        if (dataMap.containsKey('Occasion__c')) {
            opp.Occasion__c = (String) dataMap.get('Occasion__c');
        }
        
        if (dataMap.containsKey('Coffee_service_start_time__c') && String.isNotBlank((String) dataMap.get('Coffee_service_start_time__c'))) {
            String timeStr = (String) dataMap.get('Coffee_service_start_time__c');
            List<String> timeParts = timeStr.split(':');
            opp.Coffee_service_start_time__c = Time.newInstance(
                Integer.valueOf(timeParts[0]), 
                Integer.valueOf(timeParts[1]), 
                0, 
                0
            );
        }
        
        if (dataMap.containsKey('Coffee_service_end_time__c') && String.isNotBlank((String) dataMap.get('Coffee_service_end_time__c'))) {
            String timeStr = (String) dataMap.get('Coffee_service_end_time__c');
            List<String> timeParts = timeStr.split(':');
            opp.Coffee_service_end_time__c = Time.newInstance(
                Integer.valueOf(timeParts[0]), 
                Integer.valueOf(timeParts[1]), 
                0, 
                0
            );
        }
        
        if (dataMap.containsKey('Beverages_Coffee_Type__c')) {
            opp.Beverages_Coffee_Type__c = (String) dataMap.get('Beverages_Coffee_Type__c');
        }
        
        if (dataMap.containsKey('Guest_arrival_time__c') && String.isNotBlank((String) dataMap.get('Guest_arrival_time__c'))) {
            String dateTimeStr = (String) dataMap.get('Guest_arrival_time__c');
            opp.Guest_arrival_time__c = DateTime.valueOf(dateTimeStr.replace('T', ' '));
        }
        
        if (dataMap.containsKey('Cart_Area__c')) {
            opp.Cart_Area__c = (String) dataMap.get('Cart_Area__c');
        }
        
        if (dataMap.containsKey('Access_Instructions__c')) {
            opp.Access_Instructions__c = (String) dataMap.get('Access_Instructions__c');
        }
        
        if (dataMap.containsKey('Setup_Breakdown__c')) {
            opp.Setup_Breakdown__c = (String) dataMap.get('Setup_Breakdown__c');
        }
        
        if (dataMap.containsKey('Branding_preference__c')) {
            opp.Branding_preference__c = (String) dataMap.get('Branding_preference__c');
        }
        
        if (dataMap.containsKey('Signage_requirement__c')) {
            opp.Signage_requirement__c = (String) dataMap.get('Signage_requirement__c');
        }
        
        if (dataMap.containsKey('Coffee_cart_to_be_branded_or_customized__c')) {
            opp.Coffee_cart_to_be_branded_or_customized__c = (Boolean) dataMap.get('Coffee_cart_to_be_branded_or_customized__c');
        }
        
        if (dataMap.containsKey('Additional_beverages_or_snacks__c')) {
            opp.Additional_beverages_or_snacks__c = (String) dataMap.get('Additional_beverages_or_snacks__c');
        }
        
        if (dataMap.containsKey('Special_Requests__c')) {
            opp.Special_Requests__c = (String) dataMap.get('Special_Requests__c');
        }
        
        if (dataMap.containsKey('Speciality_Items__c')) {
            opp.Speciality_Items__c = (String) dataMap.get('Speciality_Items__c');
        }

        // NEW: Map Event Logo/Theme field
        if (dataMap.containsKey('Event_Logo_Theme__c')) {
            opp.Event_Logo_Theme__c = (String) dataMap.get('Event_Logo_Theme__c');
        }
        
        return opp;
    }

    /**
     * Map fields specific to Standard Layout (Sydney, Catering, Melbourne)
     */
    private static Opportunity mapStandardLayoutFields(Opportunity opp, Map<String, Object> dataMap) {
        if (dataMap.containsKey('Occasion__c')) {
            opp.Occasion__c = (String) dataMap.get('Occasion__c');
        }
        
        if (dataMap.containsKey('Personal_or_Corporate_Event__c')) {
            opp.Personal_or_Corporate_Event__c = (String) dataMap.get('Personal_or_Corporate_Event__c');
        }
        
        if (dataMap.containsKey('Number_of_Staff_Required__c') && dataMap.get('Number_of_Staff_Required__c') != null) {
            opp.Number_of_Staff_Required__c = (Decimal) dataMap.get('Number_of_Staff_Required__c');
        }
        
        if (dataMap.containsKey('Guest_arrival_time__c') && String.isNotBlank((String) dataMap.get('Guest_arrival_time__c'))) {
            String dateTimeStr = (String) dataMap.get('Guest_arrival_time__c');
            opp.Guest_arrival_time__c = DateTime.valueOf(dateTimeStr.replace('T', ' '));
        }
        
        if (dataMap.containsKey('Guest_departure_time__c') && String.isNotBlank((String) dataMap.get('Guest_departure_time__c'))) {
            String dateTimeStr = (String) dataMap.get('Guest_departure_time__c');
            opp.Guest_departure_time__c = DateTime.valueOf(dateTimeStr.replace('T', ' '));
        }
        
        if (dataMap.containsKey('Priority__c')) {
            opp.Priority__c = (String) dataMap.get('Priority__c');
        }
        
        if (dataMap.containsKey('Client_Breif__c')) {
            opp.Client_Breif__c = (String) dataMap.get('Client_Breif__c');
        }
        
        if (dataMap.containsKey('Uniform_Required__c')) {
            opp.Uniform_Required__c = (String) dataMap.get('Uniform_Required__c');
        }
        
        if (dataMap.containsKey('Need_extra_services__c')) {
            opp.Need_extra_services__c = (String) dataMap.get('Need_extra_services__c');
        }
        
        if (dataMap.containsKey('Do_you_have_a_budget__c')) {
            opp.Do_you_have_a_budget__c = (String) dataMap.get('Do_you_have_a_budget__c');
        }
        
        if (dataMap.containsKey('Special_Requirements__c')) {
            opp.Special_Requirements__c = (String) dataMap.get('Special_Requirements__c');
        }
        
        if (dataMap.containsKey('Anything_else_we_need_to_know__c')) {
            opp.Anything_else_we_need_to_know__c = (String) dataMap.get('Anything_else_we_need_to_know__c');
        }
        
        return opp;
    }

}