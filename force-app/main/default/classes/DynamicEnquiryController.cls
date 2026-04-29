public with sharing class DynamicEnquiryController {
    
    /**
     * Check if user has access to record type selection
     * Uses Custom Label to get the allowed profile name
     */
    @AuraEnabled
    public static Map<String, Boolean> checkUserProfile(String userId) {
        Map<String, Boolean> result = new Map<String, Boolean>();
        
        try {
            // Get allowed profile name from Custom Label
            String allowedProfileName = System.Label.Custom_Customer_Community_User;
            
            // Get Profile ID from Profile Name
            Profile allowedProfile = [
                SELECT Id 
                FROM Profile 
                WHERE Name = :allowedProfileName 
                LIMIT 1
            ];
            
            User currentUser = [
                SELECT Id, ProfileId 
                FROM User 
                WHERE Id = :userId 
                LIMIT 1
            ];
            
            // Check if user's profile matches the allowed profile
            if (currentUser.ProfileId == allowedProfile.Id) {
                result.put('hasAccess', true);
            } else {
                result.put('hasAccess', false);
            }
            
            return result;
        } catch (Exception e) {
            // If profile not found or any error, deny access
            System.debug('Error checking profile: ' + e.getMessage());
            result.put('hasAccess', false);
            return result;
        }
    }
    
    /**
     * Get record types for logged-in community users
     * Returns Sydney_Bookings, Catering, Coffee_Cart, Melbourne_Bookings
     */
    @AuraEnabled(cacheable=true)
    public static List<RecordType> getRecordTypesForUser() {
        try {
            return [
                SELECT Id, Name, DeveloperName 
                FROM RecordType 
                WHERE SObjectType = 'Opportunity' 
                AND IsActive = true
                AND DeveloperName IN ('Sydney_Bookings', 'Catering', 'Coffee_Cart', 'Melbourne_Bookings')
                ORDER BY Name Desc
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching record types: ' + e.getMessage());
        }
    }
    
    /**
     * Get the Account ID and Contact details associated with the logged-in Community user
     * UPDATED: Now returns Account ID, Contact ID, and Contact details (Name, Email, Phone)
     */
    @AuraEnabled
    public static Map<String, String> getUserAccountId(String userId) {
        try {
            User currentUser = [
                SELECT Id, ContactId, 
                       Contact.AccountId,
                       Contact.FirstName,
                       Contact.LastName,
                       Contact.Email,
                       Contact.Phone
                FROM User 
                WHERE Id = :userId 
                LIMIT 1
            ];
            
            if (currentUser.ContactId != null && currentUser.Contact.AccountId != null) {
                Map<String, String> userDetails = new Map<String, String>();
                userDetails.put('accountId', currentUser.Contact.AccountId);
                userDetails.put('contactId', currentUser.ContactId);
                userDetails.put('firstName', currentUser.Contact.FirstName != null ? currentUser.Contact.FirstName : '');
                userDetails.put('lastName', currentUser.Contact.LastName != null ? currentUser.Contact.LastName : '');
                userDetails.put('email', currentUser.Contact.Email != null ? currentUser.Contact.Email : '');
                userDetails.put('phone', currentUser.Contact.Phone != null ? currentUser.Contact.Phone : '');
                
                return userDetails;
            } else {
                throw new AuraHandledException('No account found for this user');
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching user account: ' + e.getMessage());
        }
    }
    
    /**
     * Get picklist options for all relevant fields
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, List<PicklistValue>> getPicklistOptions() {
        Map<String, List<PicklistValue>> picklistMap = new Map<String, List<PicklistValue>>();
        
        try {
            // Get field describe results
            Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Opportunity.fields.getMap();
            
            // List of picklist fields to retrieve
            List<String> picklistFields = new List<String>{
                'Personal_or_Corporate_Event__c',
                'Event_Type__c',
                'Priority__c',
                'Client_Breif__c',
                'Uniform_Required__c',
                'Need_extra_services__c',
                'Do_you_have_a_budget__c',
                'Beverages_Coffee_Type__c'
            };
            
            for (String fieldName : picklistFields) {
                if (fieldMap.containsKey(fieldName)) {
                    Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                    List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
                    
                    List<PicklistValue> values = new List<PicklistValue>();
                    for (Schema.PicklistEntry entry : picklistEntries) {
                        if (entry.isActive()) {
                            values.add(new PicklistValue(entry.getLabel(), entry.getValue()));
                        }
                    }
                    picklistMap.put(fieldName, values);
                }
            }
            
            return picklistMap;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching picklist options: ' + e.getMessage());
        }
    }
    
    /**
     * Create Enquiry Record dynamically based on record type
     */
    @AuraEnabled
    public static Map<String, Object> createEnquiryRecord(String enquiryData, String recordTypeId, String recordTypeName) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(enquiryData);
            
            Opportunity opp = new Opportunity();
            opp.RecordTypeId = recordTypeId;
            
            // Map all common fields
            opp = mapCommonFields(opp, dataMap);
            
            // Map layout-specific fields based on record type
            if (recordTypeName == 'Sydney_Bookings' || recordTypeName == 'Catering' || recordTypeName == 'Melbourne_Bookings') {
                opp = mapStandardLayoutFields(opp, dataMap);
            } else if (recordTypeName == 'Coffee_Cart') {
                opp = mapCoffeeCartFields(opp, dataMap);
            }
            
            // Insert the record
            insert opp;
            
            // Return success response
            result.put('success', true);
            result.put('recordId', opp.Id);
            result.put('recordName', opp.Name);
            result.put('message', 'Your enquiry has been submitted successfully!');
            
        } catch (DmlException e) {
            result.put('success', false);
            result.put('message', 'Failed to submit enquiry: ' + e.getDmlMessage(0));
            throw new AuraHandledException('Error creating enquiry: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            result.put('success', false);
            result.put('message', 'Failed to submit enquiry: ' + e.getMessage());
            throw new AuraHandledException('Error creating enquiry: ' + e.getMessage());
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

        if(dataMap.containsKey('What_is_the_theme_or_style_of_the_event__c')){
            opp.What_is_the_theme_or_style_of_the_event__c = (String) dataMap.get('What_is_the_theme_or_style_of_the_event__c');
        }
        
        return opp;
    }
    
    /**
     * Wrapper class for picklist values
     */
    public class PicklistValue {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
        
        public PicklistValue(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

        /**
     * Get existing enquiry (Opportunity) for edit
     */
    @AuraEnabled(cacheable=true)
    public static Opportunity getEnquiryForEdit(Id recordId) {
        try {
            if (recordId == null) {
                throw new AuraHandledException('Record Id is required.');
            }

            Opportunity opp = [
                SELECT Id, Name, StageName, CloseDate, AccountId, RecordTypeId,
                       RecordType.DeveloperName,
                       First_Name__c, Last_Name__c, Phone_Number__c, Email_Address__c,
                       Event_Date__c, Event_Time__c,
                       Number_of_Guests__c, Estimated_Budget__c,
                       Venue_Address__c, Event_Type__c,
                       //Standard layout fields
                       Occasion__c, Personal_or_Corporate_Event__c,
                       Number_of_Staff_Required__c,
                       Guest_arrival_time__c, Guest_departure_time__c,
                       Priority__c, Client_Breif__c,
                       Uniform_Required__c, Need_extra_services__c,
                       Do_you_have_a_budget__c,
                       Special_Requirements__c, Anything_else_we_need_to_know__c,
                       //Coffee Cart fields
                       Event_Location__c,
                       Coffee_service_start_time__c, Coffee_service_end_time__c,
                       Beverages_Coffee_Type__c,
                       Cart_Area__c, Access_Instructions__c, Setup_Breakdown__c,
                       Branding_preference__c, Signage_requirement__c,
                       Coffee_cart_to_be_branded_or_customized__c,
                       Additional_beverages_or_snacks__c,
                       Special_Requests__c, Speciality_Items__c,
                       Event_Logo_Theme__c,
                       What_is_the_theme_or_style_of_the_event__c
                FROM Opportunity
                WHERE Id = :recordId
                LIMIT 1
            ];

            return opp;

        } catch (Exception e) {
            throw new AuraHandledException('Error fetching enquiry: ' + e.getMessage());
        }
    }

    /**
     * Update an existing enquiry (Opportunity) for ANY supported record type.
     * Uses the same mapping helpers as createEnquiryRecord.
     */
   
    public static Map<String, Object> updateEnquiryRecordInternal(String enquiryData, Id recordId) {
        Map<String, Object> result = new Map<String, Object>();

        try {
            if (recordId == null) {
                throw new AuraHandledException('Record Id is required.');
            }

            // Load existing Opportunity (to get its RecordType as well)
            Opportunity opp = [
                SELECT Id, RecordTypeId, RecordType.DeveloperName
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




}