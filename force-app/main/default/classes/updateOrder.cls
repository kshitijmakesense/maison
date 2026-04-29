public without sharing class updateOrder {
     @AuraEnabled
    public static Map<String, Object> updateOrderRecordInternal(String orderData, Id recordId) {
        Map<String, Object> result = new Map<String, Object>();

        try {
            if (recordId == null)
                throw new AuraHandledException('Record Id is required.');

            // Load existing record
            Order ord = [
                SELECT Id, RecordTypeId, RecordType.DeveloperName
                FROM Order
                WHERE Id = :recordId
                LIMIT 1
            ];

            // Deserialize LWC JSON
            Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(orderData);

            // Map COMMON fields
            ord = mapCommonFields(ord, dataMap);

            // Map STANDARD or COFFEE-CART layouts
            String rt = ord.RecordType.DeveloperName;

            if (rt == 'Sydney_Bookings' ||
                rt == 'Catering' ||
                rt == 'Melbourne_Bookings') {

                ord = mapStandardFields(ord, dataMap);

            } else if (rt == 'Coffee_Cart') {

                ord = mapCoffeeCartFields(ord, dataMap);
            }

            update ord;

            result.put('success', true);
            result.put('recordId', ord.Id);
            result.put('message', 'Booking Order updated successfully!');

        } catch (DmlException e) {
            throw new AuraHandledException('Error updating order: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Error updating order: ' + e.getMessage());
        }

        return result;
    }

    /*-----------------------------------------------------
     *  COMMON FIELD MAPPING
     *-----------------------------------------------------*/
    private static Order mapCommonFields(Order ord, Map<String, Object> data) {

     
        if (data.containsKey('Event_Date__c'))
            ord.Event_Date__c = Date.valueOf((String) data.get('Event_Date__c'));

        if (data.containsKey('Event_Time__c') && String.isNotBlank((String) data.get('Event_Time__c'))) {
            String t = (String) data.get('Event_Time__c');
            List<String> p = t.split(':');
            ord.Event_Time__c = Time.newInstance(Integer.valueOf(p[0]), Integer.valueOf(p[1]), 0, 0);
        }

        if (data.containsKey('Number_of_Guests__c') && data.get('Number_of_Guests__c') != null)
            ord.Number_of_Guests__c = (Decimal) data.get('Number_of_Guests__c');

        if (data.containsKey('Estimated_Budget__c') && data.get('Estimated_Budget__c') != null)
            ord.Estimated_Budget__c = (Decimal) data.get('Estimated_Budget__c');

        if (data.containsKey('Venue_Address__c'))
            ord.Venue_Address__c = (String) data.get('Venue_Address__c');

        if (data.containsKey('Event_Type__c'))
            ord.Event_Type__c = (String) data.get('Event_Type__c');

        return ord;
    }

    /*-----------------------------------------------------
     *  STANDARD LAYOUT FIELD MAPPING
     *-----------------------------------------------------*/
    private static Order mapStandardFields(Order ord, Map<String, Object> data) {

        if (data.containsKey('Occasion__c'))
            ord.Occasion__c = (String) data.get('Occasion__c');

        if (data.containsKey('Personal_or_Corporate_Event__c'))
            ord.Personal_or_Corporate_Event__c = (String) data.get('Personal_or_Corporate_Event__c');

        if (data.containsKey('Number_of_Staff_Required__c') && data.get('Number_of_Staff_Required__c') != null)
            ord.Number_of_Staff_Required__c = (Decimal) data.get('Number_of_Staff_Required__c');

        if (data.containsKey('Guest_arrival_time__c')) {
            String dt = (String) data.get('Guest_arrival_time__c');
            if (String.isNotBlank(dt))
                ord.Guest_arrival_time__c = DateTime.valueOf(dt.replace('T', ' '));
        }

        if (data.containsKey('Guest_departure_time__c')) {
            String dt = (String) data.get('Guest_departure_time__c');
            if (String.isNotBlank(dt))
                ord.Guest_departure_time__c = DateTime.valueOf(dt.replace('T', ' '));
        }

        if (data.containsKey('Priority__c')) ord.Priority__c = (String) data.get('Priority__c');
        if (data.containsKey('Client_Breif__c')) ord.Client_Breif__c = (String) data.get('Client_Breif__c');
        if (data.containsKey('Uniform_Required__c')) ord.Uniform_Required__c = (String) data.get('Uniform_Required__c');
        if (data.containsKey('Need_extra_services__c')) ord.Need_extra_services__c = (String) data.get('Need_extra_services__c');
        if (data.containsKey('Do_you_have_a_budget__c')) ord.Do_you_have_a_budget__c = (String) data.get('Do_you_have_a_budget__c');
        if (data.containsKey('Special_Requirements__c')) ord.Special_Requirements__c = (String) data.get('Special_Requirements__c');
   
        return ord;
    }

    /*-----------------------------------------------------
     *  COFFEE CART FIELD MAPPING
     *-----------------------------------------------------*/
    private static Order mapCoffeeCartFields(Order ord, Map<String, Object> data) {

        if (data.containsKey('Event_Location__c'))
            ord.Event_Location__c = (String) data.get('Event_Location__c');

        if (data.containsKey('Occasion__c'))
            ord.Occasion__c = (String) data.get('Occasion__c');

        if (data.containsKey('Coffee_service_start_time__c')) {
            String t = (String) data.get('Coffee_service_start_time__c');
            if (String.isNotBlank(t)) {
                List<String> p = t.split(':');
                ord.Coffee_service_start_time__c =
                    Time.newInstance(Integer.valueOf(p[0]), Integer.valueOf(p[1]), 0, 0);
            }
        }

        if (data.containsKey('Coffee_service_end_time__c')) {
            String t = (String) data.get('Coffee_service_end_time__c');
            if (String.isNotBlank(t)) {
                List<String> p = t.split(':');
                ord.Coffee_service_end_time__c =
                    Time.newInstance(Integer.valueOf(p[0]), Integer.valueOf(p[1]), 0, 0);
            }
        }

        if (data.containsKey('Beverages_Coffee_Type__c'))
            ord.Beverages_Coffee_Type__c = (String) data.get('Beverages_Coffee_Type__c');

        if (data.containsKey('Cart_Area__c'))
            ord.Cart_Area__c = (String) data.get('Cart_Area__c');

        if (data.containsKey('Access_Instructions__c'))
            ord.Access_Instructions__c = (String) data.get('Access_Instructions__c');

        if (data.containsKey('Setup_Breakdown__c'))
            ord.Setup_Breakdown__c = (String) data.get('Setup_Breakdown__c');

        if (data.containsKey('Branding_preference__c'))
            ord.Branding_preference__c = (String) data.get('Branding_preference__c');

        if (data.containsKey('Signage_requirement__c'))
            ord.Signage_requirement__c = (String) data.get('Signage_requirement__c');

        if (data.containsKey('Coffee_cart_to_be_branded_or_customized__c'))
            ord.Coffee_cart_to_be_branded_or_customized__c =
                (Boolean) data.get('Coffee_cart_to_be_branded_or_customized__c');

        if (data.containsKey('Additional_beverages_or_snacks__c'))
            ord.Additional_beverages_or_snacks__c = (String) data.get('Additional_beverages_or_snacks__c');

        if (data.containsKey('Special_Requests__c'))
            ord.Special_Requests__c = (String) data.get('Special_Requests__c');

        if (data.containsKey('Speciality_Items__c'))
            ord.Speciality_Items__c = (String) data.get('Speciality_Items__c');

        if (data.containsKey('Event_Logo_Theme__c'))
            ord.Event_Logo_Theme__c = (String) data.get('Event_Logo_Theme__c');

    
        return ord;
    }
}