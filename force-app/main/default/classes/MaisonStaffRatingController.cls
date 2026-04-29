public with sharing class MaisonStaffRatingController {

    // ============================================
    // 🔹 FETCH STAFF FOR A BOOKING
    // ============================================
  @AuraEnabled
public static List<StaffWrapper> getStaffByBooking(Id bookingId) {

    // 🔹 Get current user's contact
    Id contactId;
    User u = [
        SELECT ContactId 
        FROM User 
        WHERE Id = :UserInfo.getUserId()
        LIMIT 1
    ];
    contactId = u.ContactId;

    // 🔹 Fetch existing ratings
    Map<Id, Staff_Rating__c> ratingMap = new Map<Id, Staff_Rating__c>();

    for (Staff_Rating__c sr : [
        SELECT Staff__c, Rating__c, Comments__c
        FROM Staff_Rating__c
        WHERE Booking__c = :bookingId
        AND Contact__c = :contactId
    ]) {
        ratingMap.put(sr.Staff__c, sr);
    }

    // 🔹 Fetch staff
    List<StaffWrapper> result = new List<StaffWrapper>();
    Set<Id> seenStaff = new Set<Id>();

    for (Booking_Staff_Assignment__c bsa : [
        SELECT Staff__c, Staff__r.Name, Staff__r.Last_Name__c
        FROM Booking_Staff_Assignment__c
        WHERE Booking_Order__c = :bookingId
    ]) {

        if (seenStaff.contains(bsa.Staff__c)) continue;
        seenStaff.add(bsa.Staff__c);

        String fullName = bsa.Staff__r.Name;
        if (bsa.Staff__r.Last_Name__c != null) {
            fullName += ' ' + bsa.Staff__r.Last_Name__c;
        }

        Integer rating = 0;
        String comment = '';

        if (ratingMap.containsKey(bsa.Staff__c)) {
            rating = (Integer) ratingMap.get(bsa.Staff__c).Rating__c;
            comment = ratingMap.get(bsa.Staff__c).Comments__c;
        }

       result.add(new StaffWrapper(
    bsa.Staff__c,
    fullName,
    rating,
    comment,
    getStaffPhotoUrl(bsa.Staff__c)
));
    }

    return result;
}


    // ============================================
    // 🔹 SAVE RATINGS (BULK SAFE)
    // ============================================
   @AuraEnabled
public static void saveRatings(String ratingsJson) {

    List<StaffRatingWrapper> ratings =
        (List<StaffRatingWrapper>) JSON.deserialize(ratingsJson, List<StaffRatingWrapper>.class);

        if (ratings == null || ratings.isEmpty()) return;

        Set<Id> bookingIds = new Set<Id>();
        Set<Id> staffIds = new Set<Id>();

        for (StaffRatingWrapper r : ratings) {
            bookingIds.add(r.bookingId);
            staffIds.add(r.staffId);
        }

        // 🔥 Fetch existing ratings in ONE query
        Map<String, Staff_Rating__c> existingMap = new Map<String, Staff_Rating__c>();

        for (Staff_Rating__c sr : [
            SELECT Id, Booking__c, Staff__c
            FROM Staff_Rating__c
            WHERE Booking__c IN :bookingIds
            AND Staff__c IN :staffIds
        ]) {
            String key = sr.Booking__c + '-' + sr.Staff__c;
            existingMap.put(key, sr);
        }

        List<Staff_Rating__c> recordsToInsert = new List<Staff_Rating__c>();
        List<Staff_Rating__c> recordsToUpdate = new List<Staff_Rating__c>();

        Id contactId;

User u = [
    SELECT ContactId 
    FROM User 
    WHERE Id = :UserInfo.getUserId()
    LIMIT 1
];

contactId = u.ContactId;

        for (StaffRatingWrapper r : ratings) {

            String key = r.bookingId + '-' + r.staffId;

            if (existingMap.containsKey(key)) {
                // 🔁 UPDATE existing rating
                Staff_Rating__c existing = existingMap.get(key);
                existing.Rating__c = r.rating;
                existing.Comments__c = r.comment;
                recordsToUpdate.add(existing);

            } else {
                // ➕ INSERT new rating
              if (contactId != null) {
                recordsToInsert.add(new Staff_Rating__c(
                    Booking__c = r.bookingId,
                    Staff__c = r.staffId,
                    Rating__c = r.rating,
                    Comments__c = r.comment,
                    Contact__c = contactId,
                    Submitted_Date__c = System.today()
                ));
            }
            }
        }

        if (!recordsToInsert.isEmpty()) {
            insert recordsToInsert;
        }

        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }


    // ============================================
    // 🔹 WRAPPER: STAFF DATA
    // ============================================
   public class StaffWrapper {
    @AuraEnabled public Id id;
    @AuraEnabled public String name;
    @AuraEnabled public Integer rating;
    @AuraEnabled public String comment;
    @AuraEnabled public String photoUrl;

    public StaffWrapper(Id id, String name, Integer rating, String comment, String photoUrl) {
    this.id = id;
    this.name = name;
    this.rating = rating;
    this.comment = comment;
    this.photoUrl = photoUrl;
}
}


private static String getStaffPhotoUrl(Id staffId) {
    List<ContentDocumentLink> cdLinks = [
        SELECT ContentDocument.LatestPublishedVersionId
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :staffId
        ORDER BY ContentDocument.CreatedDate DESC
        LIMIT 1
    ];

    if (!cdLinks.isEmpty()) {
        return URL.getOrgDomainUrl().toExternalForm() +
            '/sfc/servlet.shepherd/version/download/' +
            cdLinks[0].ContentDocument.LatestPublishedVersionId;
    }

    return null;
}


    // ============================================
    // 🔹 WRAPPER: RATING INPUT
    // ============================================
    public class StaffRatingWrapper {
        @AuraEnabled public Id bookingId;
        @AuraEnabled public Id staffId;
        @AuraEnabled public Integer rating;
        @AuraEnabled public String comment;
    }
}