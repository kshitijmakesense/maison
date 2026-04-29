public with sharing class PreferredStaffFavorites {
    // DTO
    public class PreferredStaffDTO {
        @AuraEnabled public Id staffId;
        @AuraEnabled public String staffName;
        @AuraEnabled public String eventName;
        @AuraEnabled public Date eventDate;
        @AuraEnabled public Decimal avgRating;
        @AuraEnabled public String photoUrl;
    }

    @AuraEnabled
public static List<PreferredStaffDTO> getPreferredStaff(Id contactId) {

    List<PreferredStaffDTO> result = new List<PreferredStaffDTO>();

    List<Preferred_Staff__c> prefList = [
        SELECT Preferred_Staff__c,
               Preferred_Staff__r.Name, Preferred_Staff__r.Last_Name__c
        FROM Preferred_Staff__c
        WHERE Contact__c = :contactId
    ];

    Set<Id> staffIds = new Set<Id>();
    for (Preferred_Staff__c ps : prefList) {
        staffIds.add(ps.Preferred_Staff__c);
    }

    // Get latest booking per staff
    Map<Id, Booking_Staff_Assignment__c> latestMap = new Map<Id, Booking_Staff_Assignment__c>();

    for (Booking_Staff_Assignment__c a : [
        SELECT Staff__c,
               Booking_Order__r.Occasion__c,
               Booking_Order__r.Event_Date__c
        FROM Booking_Staff_Assignment__c
        WHERE Staff__c IN :staffIds
        ORDER BY Booking_Order__r.Event_Date__c DESC
    ]) {
        if (!latestMap.containsKey(a.Staff__c)) {
            latestMap.put(a.Staff__c, a);
        }
    }

    // Ratings
    Map<Id, Decimal> ratingMap = new Map<Id, Decimal>();

    for (AggregateResult ar : [
        SELECT Staff__c s, AVG(Rating__c) avgR
        FROM Staff_Rating__c
        WHERE Staff__c IN :staffIds
        GROUP BY Staff__c
    ]) {
        ratingMap.put((Id) ar.get('s'), (Decimal) ar.get('avgR'));
    }

    // Build DTO
    for (Preferred_Staff__c ps : prefList) {

        PreferredStaffDTO dto = new PreferredStaffDTO();
        dto.staffId = ps.Preferred_Staff__c;
        //dto.staffName = ps.Preferred_Staff__r.Name;
        dto.staffName =
    (ps.Preferred_Staff__r.Name != null ? ps.Preferred_Staff__r.Name : '') +
    ' ' +
    (ps.Preferred_Staff__r.Last_Name__c != null ? ps.Preferred_Staff__r.Last_Name__c : '');

        if (latestMap.containsKey(ps.Preferred_Staff__c)) {
            Booking_Staff_Assignment__c a = latestMap.get(ps.Preferred_Staff__c);
            dto.eventName = a.Booking_Order__r.Occasion__c;
            dto.eventDate = a.Booking_Order__r.Event_Date__c;
        }

       // dto.avgRating = ratingMap.get(ps.Preferred_Staff__c);
       Decimal avg = ratingMap.get(ps.Preferred_Staff__c);
       dto.avgRating = avg != null ? avg.setScale(1) : null; // ✅ 1 decimal place 
        dto.photoUrl = getStaffPhotoUrl(ps.Preferred_Staff__c);
        result.add(dto);
    }

    return result;
}

  private static String getStaffPhotoUrl(Id staffId) {
        try {
            // Query for image files attached to this staff record
            List<ContentDocumentLink> cdLinks = [
                SELECT ContentDocument.LatestPublishedVersionId,
                       ContentDocument.LatestPublishedVersion.FileExtension
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :staffId
                AND ContentDocument.LatestPublishedVersion.FileExtension IN ('jpg', 'jpeg', 'png', 'gif')
                ORDER BY ContentDocument.CreatedDate DESC
                LIMIT 1
            ];

            if (!cdLinks.isEmpty()) {
                Id versionId = cdLinks[0].ContentDocument.LatestPublishedVersionId;
                // Return the URL to access the image
                return '/sfc/servlet.shepherd/version/download/' + versionId;
            }

            // If no ContentDocument, check for Attachments (legacy)
            List<Attachment> attachments = [
                SELECT Id, Name
                FROM Attachment
                WHERE ParentId = :staffId
                AND (Name LIKE '%.jpg' OR Name LIKE '%.jpeg' OR Name LIKE '%.png' OR Name LIKE '%.gif')
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            if (!attachments.isEmpty()) {
                return '/servlet/servlet.FileDownload?file=' + attachments[0].Id;
            }

        } catch (Exception e) {
            System.debug('Error fetching staff photo: ' + e.getMessage());
        }

        return null;
    }
}