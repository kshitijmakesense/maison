public without sharing class PreferredStaffService {

    // DTO
    public class PreferredStaffDTO {
        @AuraEnabled public Id staffId;
        @AuraEnabled public String staffName;
        @AuraEnabled public String eventName;
        @AuraEnabled public Date eventDate;
        @AuraEnabled public Decimal avgRating;
        @AuraEnabled public String photoUrl;
    }

    public class ResponseWrapper {
        @AuraEnabled public List<PreferredStaffDTO> records;
        @AuraEnabled public Integer totalCount;
    }

@AuraEnabled
public static ResponseWrapper getPreferredStaff(Id contactId, Integer pageSize, Integer offsetSize){

      ResponseWrapper res = new ResponseWrapper();
        res.records = new List<PreferredStaffDTO>();


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

    List<PreferredStaffDTO> allRecords = result;
res.totalCount = allRecords.size();

Integer endPage = Math.min(offsetSize + pageSize, allRecords.size());

for (Integer i = offsetSize; i < endPage; i++) {
    res.records.add(allRecords[i]);
}

return res;
}

private static void ensureFileAccess(Id staffId, Id contentDocId) {

    List<ContentDocumentLink> links = [
        SELECT Id, Visibility
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :staffId
        AND ContentDocumentId = :contentDocId
        LIMIT 1
    ];

    if (!links.isEmpty() && links[0].Visibility != 'AllUsers') {
        links[0].Visibility = 'AllUsers';
        update links;
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

  // =========================
    // 🔥 FIXED IMAGE METHOD
    // =========================
    /*private static String getStaffPhotoUrl(Id staffId) {

        List<ContentDocumentLink> cdLinks = [
            SELECT ContentDocumentId,
                   ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :staffId
            ORDER BY ContentDocument.CreatedDate DESC
            LIMIT 1
        ];

        if (!cdLinks.isEmpty()) {

            Id docId = cdLinks[0].ContentDocumentId;
            Id versionId = cdLinks[0].ContentDocument.LatestPublishedVersionId;

            // Ensure portal access
            ensureFileAccess(staffId, docId);

            // 🔥 USE RENDITION (NO MORE 503 / FLICKER)
            return '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB240BY180&versionId=' + versionId;
        }

        return null;
    }*/
    // MAIN FETCH METHOD
    @AuraEnabled
    public static ResponseWrapper getEligibleStaff(Id contactId, Integer pageSize, Integer offsetSize) {

        ResponseWrapper res = new ResponseWrapper();
        res.records = new List<PreferredStaffDTO>();

        // 1️⃣ Already preferred staff
      Set<Id> preferredStaffIds = new Set<Id>();

        for (Preferred_Staff__c ps : [
            SELECT Preferred_Staff__c 
            FROM Preferred_Staff__c 
            WHERE Contact__c = :contactId
        ]) {
            preferredStaffIds.add(ps.Preferred_Staff__c);
        }

        // 2️⃣ Fetch assignments (past + active staff)
        List<Booking_Staff_Assignment__c> assignments = [
            SELECT Staff__c,
                   Staff__r.Name, Staff__r.Last_Name__c,
                   Staff__r.Active__c,
                   Booking_Order__r.Occasion__c,
                   Booking_Order__r.Event_Date__c
            FROM Booking_Staff_Assignment__c
            WHERE Booking_Order__r.Contact__c = :contactId
            AND Booking_Order__r.Event_Date__c < TODAY
            AND Booking_Order__r.Status = 'Closed'
            AND Booking_Order__r.Event_Outcome__c = 'Event Completed'
            AND Staff__r.Active__c = true
            AND Staff__c NOT IN :preferredStaffIds
            ORDER BY Booking_Order__r.Event_Date__c DESC
        ];

        // 3️⃣ Deduplicate (latest event per staff)
        Map<Id, PreferredStaffDTO> staffMap = new Map<Id, PreferredStaffDTO>();

        for (Booking_Staff_Assignment__c a : assignments) {
            if (!staffMap.containsKey(a.Staff__c)) {
                PreferredStaffDTO dto = new PreferredStaffDTO();
                dto.staffId = a.Staff__c;
                //dto.staffName = a.Staff__r.Name;
                dto.staffName =
    (a.Staff__r.Name != null ? a.Staff__r.Name : '') +
    ' ' +
    (a.Staff__r.Last_Name__c != null ? a.Staff__r.Last_Name__c : '');
                dto.eventName = a.Booking_Order__r.Occasion__c;
                dto.eventDate = a.Booking_Order__r.Event_Date__c;
                staffMap.put(a.Staff__c, dto);
                dto.photoUrl = getStaffPhotoUrl(a.Staff__c);
            }
        }

        List<PreferredStaffDTO> allRecords = staffMap.values();
        res.totalCount = allRecords.size();

        // 4️⃣ Pagination manually
        Integer endPage = Math.min(offsetSize + pageSize, allRecords.size());

        for (Integer i = offsetSize; i < endPage; i++) {
            res.records.add(allRecords[i]);
        }

        // 5️⃣ Fetch ratings
        Set<Id> staffIds = new Set<Id>();
        for (PreferredStaffDTO dto : res.records) {
            staffIds.add(dto.staffId);
        }

        Map<Id, Decimal> ratingMap = new Map<Id, Decimal>();

        for (AggregateResult ar : [
            SELECT Staff__c s, AVG(Rating__c) avgR
            FROM Staff_Rating__c
            WHERE Staff__c IN :staffIds
            GROUP BY Staff__c
        ]) {
            ratingMap.put((Id) ar.get('s'), (Decimal) ar.get('avgR'));
        }

        /*for (PreferredStaffDTO dto : res.records) {
            dto.avgRating = ratingMap.get(dto.staffId);
        }*/
        for (PreferredStaffDTO dto : res.records) {
            Decimal avg = ratingMap.get(dto.staffId);
            dto.avgRating = avg != null ? avg.setScale(1) : null;
        }

        return res;
    }

    // MARK AS PREFERRED
    @AuraEnabled
    public static void markPreferred(Id contactId, List<Id> staffIds) {

        List<Preferred_Staff__c> records = new List<Preferred_Staff__c>();

        for (Id staffId : staffIds) {
            records.add(new Preferred_Staff__c(
                Contact__c = contactId,
                Preferred_Staff__c = staffId
            ));
        }

        insert records;
    }

@AuraEnabled
public static void removePreferredBulk(Id contactId, List<Id> staffIds) {

    List<Preferred_Staff__c> records = [
        SELECT Id
        FROM Preferred_Staff__c
        WHERE Contact__c = :contactId
        AND Preferred_Staff__c IN :staffIds
    ];

    delete records;
}
}