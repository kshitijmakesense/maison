public without sharing class CoffeeCartBookingController {
    @AuraEnabled
    public static String saveBooking(Map<String, Object> bookingData) {

        // Get logged-in Experience Cloud User info
        User loggedInUser = [
            SELECT Id, ContactId,
                   Contact.FirstName,
                   Contact.LastName,
                   Contact.AccountId,
                   Contact.Email,
                   Contact.Phone
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        // Get Coffee Cart Record Type dynamically
        Id coffeeCartRTId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Opportunity'
              AND DeveloperName = 'Coffee_Cart'
            LIMIT 1
        ].Id;

        // Create Opportunity record
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = coffeeCartRTId;
        opp.StageName = 'New Enquiry';
        opp.CloseDate = Date.today().addDays(7);

        // Assign logged-in user's Account and Contact
        opp.AccountId = loggedInUser.Contact.AccountId;
        opp.ContactId = loggedInUser.ContactId;

        // Contact info mapping
        opp.Email_Address__c = loggedInUser.Contact.Email;
        opp.Phone_Number__c = loggedInUser.Contact.Phone;

        // ⭐ NEWLY ADDED (you requested)
        opp.First_Name__c = loggedInUser.Contact.FirstName;
        opp.Last_Name__c = loggedInUser.Contact.LastName;

        // ⭐ Map event theme → Opportunity Occassion
        if (bookingData.containsKey('What_is_the_theme_or_style_of_the_event__c')) {
            opp.Occasion__c = (String) bookingData.get('What_is_the_theme_or_style_of_the_event__c');

        }

       // Map form input fields → Opportunity fields
Date eventDate; 

// First extract Event_Date__c (needed for DateTime combination later)
if (bookingData.containsKey('Event_Date__c') && bookingData.get('Event_Date__c') instanceof String) {
    String ed = (String) bookingData.get('Event_Date__c');
    if (String.isNotBlank(ed)) {
        eventDate = Date.valueOf(ed);
    }
}

for (String key : bookingData.keySet()) {
    
    // Skip anything not in Opportunity
    if (!Opportunity.SObjectType.getDescribe().fields.getMap().containsKey(key)) {
        continue;
    }

    Object val = bookingData.get(key);
    Schema.SObjectField fieldInfo = Opportunity.SObjectType.getDescribe().fields.getMap().get(key);
    Schema.DisplayType dt = fieldInfo.getDescribe().getType();

    // 1️⃣ BOOLEAN FIELDS
    if (dt == Schema.DisplayType.Boolean) {
        if (val instanceof String) {
            val = ((String) val).toLowerCase() == 'true';
        }
    }

    // 2️⃣ DATE FIELDS
    else if (dt == Schema.DisplayType.Date) {
        if (val instanceof String) {
            String s = ((String) val).trim();
            val = s == '' ? null : Date.valueOf(s);
        }
    }

    // 3️⃣ TIME FIELDS (pure Time)
    else if (dt == Schema.DisplayType.Time) {
        if (val instanceof String) {
            String s = (String) val;
            if (String.isBlank(s)) {
                val = null;
            } else {
                if (s.contains('.')) {
                    s = s.substring(0, s.indexOf('.'));
                }
                List<String> parts = s.split(':');
                val = Time.newInstance(
                    Integer.valueOf(parts[0]),
                    Integer.valueOf(parts[1]),
                    Integer.valueOf(parts[2]),
                    0
                );
            }
        }
    }

    // 4️⃣ DATETIME FIELDS (combine Event Date + Time)
    else if (dt == Schema.DisplayType.DateTime) {
        if (val instanceof String) {

            String timeString = (String) val;

            if (String.isBlank(timeString) || eventDate == null) {
                val = null;
            } else {

                if (timeString.contains('.')) {
                    timeString = timeString.substring(0, timeString.indexOf('.'));
                }

                List<String> parts = timeString.split(':');
                Integer hh = Integer.valueOf(parts[0]);
                Integer mm = Integer.valueOf(parts[1]);
                Integer ss = Integer.valueOf(parts[2]);

                val = DateTime.newInstance(
                    eventDate.year(),
                    eventDate.month(),
                    eventDate.day(),
                    hh, mm, ss
                );
            }
        }
    }

    // 5️⃣ NUMBER / DECIMAL / CURRENCY FIELDS
    else if (dt == Schema.DisplayType.Integer ||
             dt == Schema.DisplayType.Double ||
             dt == Schema.DisplayType.Currency ||
             dt == Schema.DisplayType.Percent) {

        if (val instanceof String) {
            String num = (String) val;
            val = String.isBlank(num) ? null : Decimal.valueOf(num);
        }
    }

    // 6️⃣ DEFAULT — use the raw value
    // (text, picklist, long text, rich text)
    else {
        // no change needed
    }

    // Save to Opportunity record
    opp.put(key, val);
}


        insert opp;
        return 'SUCCESS';
    }
}