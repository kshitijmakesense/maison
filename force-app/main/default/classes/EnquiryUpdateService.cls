public without sharing class EnquiryUpdateService {

    @AuraEnabled
    public static Map<String, Object> updateEnquiryRecordInternal(String enquiryData, Id recordId) {
        Map<String, Object> result = new Map<String, Object>();

        try {
            if (recordId == null) {
                throw new AuraHandledException('Record Id is required.');
            }

            // Load existing Opportunity (to get its RecordType as well)
            Opportunity opp = [
                SELECT Id, RecordTypeId, RecordType.DeveloperName, Name
                FROM Opportunity
                WHERE Id = :recordId
                LIMIT 1
            ];

            // Deserialize JSON from LWC
            Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(enquiryData);

            // Map common fields (Name, StageName, CloseDate, common custom fields)
            opp = mapCommonFields(opp, dataMap);

            // Decide layout based on existing RecordType
            String recordTypeName = opp.RecordType.DeveloperName;

            if (recordTypeName == 'Sydney_Bookings' ||
                recordTypeName == 'Catering' ||
                recordTypeName == 'Melbourne_Bookings') {

                opp = mapStandardLayoutFields(opp, dataMap);

            } else if (recordTypeName == 'Coffee_Cart') {

                opp = mapCoffeeCartFields(opp, dataMap);
            }

            // Perform update
            update opp;

            result.put('success', true);
            result.put('recordId', opp.Id);
            result.put('recordName', opp.Name);
            result.put('message', 'Your enquiry has been updated successfully!');

        } catch (DmlException e) {
            result.put('success', false);
            result.put('message', 'Failed to update enquiry: ' + e.getDmlMessage(0));
            throw new AuraHandledException('Error updating enquiry: ' + e.getDmlMessage(0));

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
        
        if (dataMap.containsKey('Number_of_Guests__c') && dataMap.get('Number_of_Guests__c') != null) {
            opp.Number_of_Guests__c = (Decimal) dataMap.get('Number_of_Guests__c');
        }
        
        if (dataMap.containsKey('Estimated_Budget__c') && dataMap.get('Estimated_Budget__c') != null) {
            opp.Estimated_Budget__c = (Decimal) dataMap.get('Estimated_Budget__c');
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
    dateTimeStr = dateTimeStr.replace('T', ' ');
    if (dateTimeStr.length() == 16) { // "YYYY-MM-DD HH:mm"
        dateTimeStr += ':00';
    }
    opp.Guest_arrival_time__c = DateTime.valueOf(dateTimeStr);
}
        
       if (dataMap.containsKey('Guest_departure_time__c') && String.isNotBlank((String) dataMap.get('Guest_departure_time__c'))) {
    String dateTimeStr = (String) dataMap.get('Guest_departure_time__c');
    dateTimeStr = dateTimeStr.replace('T', ' ');
    if (dateTimeStr.length() == 16) { // "YYYY-MM-DD HH:mm"
        dateTimeStr += ':00';
    }
    opp.Guest_departure_time__c = DateTime.valueOf(dateTimeStr);
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
        
        /*if (dataMap.containsKey('Guest_arrival_time__c') && String.isNotBlank((String) dataMap.get('Guest_arrival_time__c'))) {
            String dateTimeStr = (String) dataMap.get('Guest_arrival_time__c');
            opp.Guest_arrival_time__c = DateTime.valueOf(dateTimeStr.replace('T', ' '));
        }*/

        if (dataMap.containsKey('Guest_arrival_time__c') && String.isNotBlank((String) dataMap.get('Guest_arrival_time__c'))) {
    String dateTimeStr = (String) dataMap.get('Guest_arrival_time__c');
    dateTimeStr = dateTimeStr.replace('T', ' ');
    if (dateTimeStr.length() == 16) { // "YYYY-MM-DD HH:mm"
        dateTimeStr += ':00';
    }
    opp.Guest_arrival_time__c = DateTime.valueOf(dateTimeStr);
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

        if(dataMap.containsKey('What_is_the_theme_or_style_of_the_event__c')){
            opp.What_is_the_theme_or_style_of_the_event__c = (String) dataMap.get('What_is_the_theme_or_style_of_the_event__c');
        }
        
        return opp;
    }
    
}