public without sharing class MaisonReorderController {

    // 🔹 1. Get Booking Details (for pre-populating modal)
 /*   @AuraEnabled(cacheable=true)
public static Map<String, Object> getBookingDetails(Id bookingId) {

    Order booking = [
        SELECT Id,
               Name,
               Occasion__c,
               Number_of_Guests__c,
               Venue_Address__c,
               Contact__c,
               Opportunity.RecordType.DeveloperName
        FROM Order
        WHERE Id = :bookingId
        LIMIT 1
    ];

    Map<String, Object> response = new Map<String, Object>();
    response.put('booking', booking);
    response.put('recordType', booking.Opportunity.RecordType.DeveloperName);

    return response;
}*/

@AuraEnabled(cacheable=true)
public static Map<String, Object> getDynamicForm(Id bookingId) {

    Order booking = [
        SELECT Id, OpportunityId
        FROM Order
        WHERE Id = :bookingId
        LIMIT 1
    ];

    Opportunity opp = [
        SELECT Id, RecordType.DeveloperName
        FROM Opportunity
        WHERE Id = :booking.OpportunityId
        LIMIT 1
    ];

    String recordType = opp.RecordType.DeveloperName;

    // 🔥 Map record type → field set
    String fieldSetName = 'Reorder_Sydney_Melbourne';

    /*if (recordType == 'Sydney_Bookings' || recordType == 'Melbourne_Bookings') fieldSetName = 'Reorder_Sydney_Melbourne';*/
    if (recordType == 'Catering') fieldSetName = 'Reorder_Catering';
    if (recordType == 'Coffee_Cart') fieldSetName = 'Reorder_Coffee_Cart';

  Schema.FieldSet fs = 
    Schema.SObjectType.Opportunity.fieldSets.getMap().get(fieldSetName);

if (fs == null) {
    throw new AuraHandledException('Field Set not found: ' + fieldSetName);
}
    List<String> fieldPaths = new List<String>();

    for (Schema.FieldSetMember f : fs.getFields()) {
        fieldPaths.add(f.getFieldPath());
    }

  Id oppId = opp.Id;

String query = 'SELECT ' + String.join(fieldPaths, ',') +
               ' FROM Opportunity WHERE Id = :oppId';

    Opportunity fullOpp = Database.query(query);

    List<Map<String, Object>> fields = new List<Map<String, Object>>();

    for (Schema.FieldSetMember f : fs.getFields()) {

        Schema.DescribeFieldResult d =
            Schema.SObjectType.Opportunity.fields.getMap()
            .get(f.getFieldPath()).getDescribe();

        Map<String, Object> fieldData = new Map<String, Object>{
            'apiName' => f.getFieldPath(),
            'label' => f.getLabel(),
            'type' => d.getType().name(),
            'required' => f.getRequired() || !d.isNillable(),
            'value' => fullOpp.get(f.getFieldPath())
        };

        // 🔥 PICKLIST SUPPORT
      if (d.getType() == Schema.DisplayType.Picklist 
 || d.getType() == Schema.DisplayType.MultiPicklist) {

            List<Map<String, String>> options = new List<Map<String, String>>();

            for (Schema.PicklistEntry pe : d.getPicklistValues()) {
                options.add(new Map<String, String>{
                    'label' => pe.getLabel(),
                    'value' => pe.getValue()
                });
            }

            fieldData.put('options', options);
        }

        fields.add(fieldData);
    }

    return new Map<String, Object>{
        'fields' => fields,
        'recordType' => recordType,
        'bookingId' => bookingId
    };
}

@AuraEnabled
public static Id createEnquiry(String dataJson) {

    Map<String, Object> data =
        (Map<String, Object>) JSON.deserializeUntyped(dataJson);

    Id bookingId = (Id) data.get('bookingId');

    Order booking = [
        SELECT Id, Contact__c, OpportunityId
        FROM Order
        WHERE Id = :bookingId
    ];

    Opportunity oldOpp = [
        SELECT Id, RecordTypeId, First_Name__c,
           Last_Name__c,
           Phone_Number__c,
           Email_Address__c   
        FROM Opportunity
        WHERE Id = :booking.OpportunityId
    ];

    Opportunity newOpp = new Opportunity();
    newOpp.RecordTypeId = oldOpp.RecordTypeId;
    newOpp.StageName = 'New Enquiry';
    newOpp.Contact__c = booking.Contact__c;
    newOpp.Cloned_From_Booking__c = bookingId;
    newOpp.First_Name__c = (String) oldOpp.First_Name__c;
    newOpp.Last_Name__c = (String) oldOpp.Last_Name__c;
newOpp.Phone_Number__c = (String) oldOpp.Phone_Number__c;
newOpp.Email_Address__c = oldOpp.Email_Address__c;
newOpp.OwnerId = System.Label.Community_Enquiry_Owner;

/*Set<String> excludedFields = new Set<String>{
    'bookingId',
    'First_Name__c',
    'Last_Name__c',
    'Phone_Number__c',
    'Email_Address__c'
};*/

Map<String, Schema.SObjectField> fieldMap =
    Schema.SObjectType.Opportunity.fields.getMap();

for (String key : data.keySet()) {

    if (key == 'bookingId') continue;

    if (fieldMap.containsKey(key)) {

        Object value = data.get(key);
        Schema.DisplayType type = fieldMap.get(key).getDescribe().getType();

        if (value != null && String.valueOf(value).trim() != '') {

            if (type == Schema.DisplayType.Date) {
                value = Date.valueOf((String) value);
            }
else if (type == Schema.DisplayType.DateTime) {

    if (value != null && String.valueOf(value).trim() != '') {

        String dt = (String) value;

        // Convert ISO → Apex format
        dt = dt.replace('T', ' ').replace('Z', '');

        if (dt.contains('.')) {
            dt = dt.substring(0, dt.indexOf('.'));
        }

        value = Datetime.valueOf(dt); // ✅ FIXED

    } else {
        value = null;
    }
}          else if (type == Schema.DisplayType.Double ||
                     type == Schema.DisplayType.Integer) {
                value = Decimal.valueOf(String.valueOf(value));
            }

        } else {
            value = null;
        }

        newOpp.put(key, value);
    }
}

    insert newOpp;
    return newOpp.Id;
}

 /*   @AuraEnabled
public static Id createEnquiry(
    Id bookingId,
    String occasion,
    Integer guests,
    String venue,
    Date eventDate,
    Datetime arrivalDateTime,
    Datetime departureDateTime
) {

    // 🔹 Step 1: Get Booking with linked Enquiry
    Order booking = [
        SELECT Id, Name, Contact__c, OpportunityId
        FROM Order
        WHERE Id = :bookingId
        LIMIT 1
    ];

    // 🔹 Step 2: Get OLD Enquiry
    Opportunity oldEnquiry = [
    SELECT Id,
           First_Name__c,
           Last_Name__c,
           Phone_Number__c,
           Email_Address__c,
           Personal_or_Corporate_Event__c,
           RecordTypeId,
           RecordType.DeveloperName,   // 🔥 ADD THIS
           Event_Type__c,
           Food_Drinks_Menu__c,
           Need_extra_services__c,
           Uniform_Required__c,
           Number_of_Staff_Required__c,

           // 🔥 ADD COFFEE CART FIELDS
           Coffee_service_start_time__c,
           Coffee_service_end_time__c,
           Estimated_Budget__c,
           Beverages_Coffee_Type__c,
           Cart_Area__c,
           Branding_preference__c,
           Setup_Breakdown__c,
           Signage_requirement__c,
           Access_Instructions__c,
           Additional_beverages_or_snacks__c,
           Speciality_Items__c,
           Special_Requests__c

    FROM Opportunity
    WHERE Id = :booking.OpportunityId
    LIMIT 1
];

    // 🔹 Step 3: Create NEW Enquiry
    Opportunity newEnquiry = new Opportunity();

    // ✅ Record Type (IMPORTANT)
    newEnquiry.RecordTypeId = oldEnquiry.RecordTypeId;

    // ✅ Basic fields (from UI)
    newEnquiry.Occasion__c = occasion;
    newEnquiry.Number_of_Guests__c = guests;
    newEnquiry.Venue_Address__c = venue;
    newEnquiry.Event_Date__c = eventDate;
 newEnquiry.Guest_Arrival_Time__c = arrivalDateTime;
newEnquiry.Guest_Departure_Time__c = departureDateTime;

    // ✅ Copy from OLD Enquiry
    newEnquiry.First_Name__c = oldEnquiry.First_Name__c;
    newEnquiry.Last_Name__c = oldEnquiry.Last_Name__c;
    newEnquiry.Phone_Number__c = oldEnquiry.Phone_Number__c;
    newEnquiry.Email_Address__c = oldEnquiry.Email_Address__c;
    newEnquiry.Personal_or_Corporate_Event__c = oldEnquiry.Personal_or_Corporate_Event__c;
    newEnquiry.Event_Type__c = oldEnquiry.Event_Type__c;
    newEnquiry.Food_Drinks_Menu__c = oldEnquiry.Food_Drinks_Menu__c;
    newEnquiry.Need_extra_services__c = oldEnquiry.Need_extra_services__c;
    newEnquiry.Uniform_Required__c = oldEnquiry.Uniform_Required__c;
    newEnquiry.Number_of_Staff_Required__c = oldEnquiry.Number_of_Staff_Required__c;
     // ✅ Other required fields
    newEnquiry.Contact__c = booking.Contact__c;
    newEnquiry.StageName = 'New Enquiry';
    // 🔗 Maintain reference
    newEnquiry.Cloned_From_Booking__c = bookingId;
    if (String.isNotBlank(System.Label.Community_Enquiry_Owner)) {
    newEnquiry.OwnerId = System.Label.Community_Enquiry_Owner;
}
// 🔥 Coffee Cart specific logic
if (oldEnquiry.RecordType.DeveloperName == 'Coffee_Cart') {

    newEnquiry.Coffee_service_start_time__c = oldEnquiry.Coffee_service_start_time__c;
    newEnquiry.Coffee_service_end_time__c = oldEnquiry.Coffee_service_end_time__c;
    newEnquiry.Estimated_Budget__c = oldEnquiry.Estimated_Budget__c;
    newEnquiry.Beverages_Coffee_Type__c = oldEnquiry.Beverages_Coffee_Type__c;
    newEnquiry.Cart_Area__c = oldEnquiry.Cart_Area__c;
    newEnquiry.Branding_preference__c = oldEnquiry.Branding_preference__c;
    newEnquiry.Setup_Breakdown__c = oldEnquiry.Setup_Breakdown__c;
    newEnquiry.Signage_requirement__c = oldEnquiry.Signage_requirement__c;
    newEnquiry.Access_Instructions__c = oldEnquiry.Access_Instructions__c;
    newEnquiry.Additional_beverages_or_snacks__c = oldEnquiry.Additional_beverages_or_snacks__c;
    newEnquiry.Speciality_Items__c = oldEnquiry.Speciality_Items__c;
    newEnquiry.Special_Requests__c = oldEnquiry.Special_Requests__c;
}

    insert newEnquiry;

 
    return newEnquiry.Id;
}*/
}