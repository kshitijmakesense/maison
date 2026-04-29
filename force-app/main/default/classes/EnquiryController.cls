public with sharing class EnquiryController {
    
    @AuraEnabled
    public static Map<String, Object> createEnquiry(Map<String, Object> enquiryData) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            // Get the Default Record Type Id
            Id defaultRecordTypeId = getDefaultRecordTypeId();
            
            if (defaultRecordTypeId == null) {
                throw new AuraHandledException('Default Record Type not found. Please contact your administrator.');
            }
            
            // Create new Opportunity record
            Opportunity opp = new Opportunity();
            
            // Set the Default Record Type
            opp.RecordTypeId = defaultRecordTypeId;
            
            // Map the fields from the form data
            if (enquiryData.containsKey('Name')) {
                opp.Name = (String) enquiryData.get('Name');
            }
            
            if (enquiryData.containsKey('Event_Type__c')) {
                opp.Event_Type__c = (String) enquiryData.get('Event_Type__c');
            }
            
            if (enquiryData.containsKey('Event_Title__c')) {
                opp.Event_Title__c = (String) enquiryData.get('Event_Title__c');
            }
            
            if (enquiryData.containsKey('Event_Date__c')) {
                opp.Event_Date__c = Date.valueOf((String) enquiryData.get('Event_Date__c'));
            }
            
            if (enquiryData.containsKey('Event_Time__c')) {
                String timeStr = (String) enquiryData.get('Event_Time__c');
                if (String.isNotBlank(timeStr)) {
                    List<String> timeParts = timeStr.split(':');
                    opp.Event_Time__c = Time.newInstance(
                        Integer.valueOf(timeParts[0]), 
                        Integer.valueOf(timeParts[1]), 
                        0, 
                        0
                    );
                }
            }
            
            if (enquiryData.containsKey('Number_of_Guests__c')) {
                opp.Number_of_Guests__c = (Decimal) enquiryData.get('Number_of_Guests__c');
            }
            
            if (enquiryData.containsKey('Estimated_Budget__c')) {
                opp.Estimated_Budget__c = (Decimal) enquiryData.get('Estimated_Budget__c');
            }
            
            if (enquiryData.containsKey('Venue_Preference__c')) {
                opp.Venue_Preference__c = (String) enquiryData.get('Venue_Preference__c');
            }
            
            if (enquiryData.containsKey('Venue_Address__c')) {
                opp.Venue_Address__c = (String) enquiryData.get('Venue_Address__c');
            }
            
            // Set required fields
            if (enquiryData.containsKey('StageName')) {
                opp.StageName = (String) enquiryData.get('StageName');
            } else {
                opp.StageName = 'New Enquiry'; // Default stage
            }
            
            if (enquiryData.containsKey('CloseDate')) {
                opp.CloseDate = Date.valueOf((String) enquiryData.get('CloseDate'));
            } else {
                opp.CloseDate = Date.today().addDays(30); // Default close date
            }
            
            // Insert the record
            insert opp;
            
            // Return success response with record details
            result.put('success', true);
            result.put('recordId', opp.Id);
            result.put('recordName', opp.Name);
          //  result.put('message', 'Enquiry submitted successfully! Your reference number is: ' + opp.Name);
           result.put('message', 'Your Enquiry submitted successfully');
            
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
     * Get the Default Record Type Id for Opportunity
     */
    private static Id getDefaultRecordTypeId() {
        try {
            // Query for the Default record type
            RecordType rt = [
                SELECT Id, Name, DeveloperName 
                FROM RecordType 
                WHERE SObjectType = 'Opportunity' 
                AND (Name = 'Default' OR DeveloperName = 'Default')
                AND IsActive = true
                LIMIT 1
            ];
            return rt.Id;
        } catch (Exception e) {
            System.debug('Error fetching Default Record Type: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * Get all active record types for Opportunity (for reference)
     */
    @AuraEnabled(cacheable=true)
    public static List<RecordTypeInfo> getOpportunityRecordTypes() {
        List<RecordTypeInfo> recordTypes = new List<RecordTypeInfo>();
        
        for (RecordType rt : [
            SELECT Id, Name, DeveloperName 
            FROM RecordType 
            WHERE SObjectType = 'Opportunity' 
            AND IsActive = true
            ORDER BY Name
        ]) {
            recordTypes.add(new RecordTypeInfo(rt.Id, rt.Name, rt.DeveloperName));
        }
        
        return recordTypes;
    }
    
    /**
     * Wrapper class for Record Type information
     */
    public class RecordTypeInfo {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String developerName { get; set; }
        
        public RecordTypeInfo(String id, String name, String developerName) {
            this.id = id;
            this.name = name;
            this.developerName = developerName;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<PicklistValue> getEventTypePicklistValues() {
        List<PicklistValue> options = new List<PicklistValue>();
        
        Schema.DescribeFieldResult fieldResult = Opportunity.Event_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry entry : ple) {
            if (entry.isActive()) {
                options.add(new PicklistValue(entry.getLabel(), entry.getValue()));
            }
        }
        
        return options;
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
}