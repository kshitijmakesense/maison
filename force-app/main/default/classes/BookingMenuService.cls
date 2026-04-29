public without sharing class BookingMenuService {

@AuraEnabled(cacheable=true)
public static List<Map<String,String>> getMenuFiles(Id bookingId) {

    List<Map<String,String>> result = new List<Map<String,String>>();

    for (ContentDocumentLink cdl : [
        SELECT ContentDocumentId,
               ContentDocument.Title,
               ContentDocument.LatestPublishedVersionId
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :bookingId
        ORDER BY ContentDocument.CreatedDate DESC
    ]) {

        ContentVersion cv = [
            SELECT File_Category__c
            FROM ContentVersion
            WHERE Id = :cdl.ContentDocument.LatestPublishedVersionId
            LIMIT 1
        ];

        // 🔥 FILTER ONLY MENU
        if (cv.File_Category__c != 'Menu') continue;

        result.add(new Map<String,String>{
            'id' => cdl.ContentDocumentId,
            'name' => cdl.ContentDocument.Title
        });

        break; // only one menu
    }

    return result;
}


@AuraEnabled
public static Id uploadMenuFile(Id bookingId, String fileName, String base64Data) {

    Blob body = EncodingUtil.base64Decode(base64Data);
    Id networkId = Network.getNetworkId(); // 🔥 important for portal

    ContentVersion cv = new ContentVersion();
    cv.Title = fileName;
    cv.PathOnClient = fileName;
    cv.VersionData = body;

    // 🔥 ADD THIS (MAIN FIX)
    cv.File_Category__c = 'Menu';

    // 🔥 ADD THIS (portal visibility fix)
    if (networkId != null) {
        cv.NetworkId = networkId;
    }

    insert cv;

    // get ContentDocumentId
    cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

    ContentDocumentLink link = new ContentDocumentLink();
    link.ContentDocumentId = cv.ContentDocumentId;
    link.LinkedEntityId = bookingId;
    link.ShareType = 'V';
    link.Visibility = 'AllUsers';
    insert link;

    return cv.ContentDocumentId;
}

@AuraEnabled
public static void deleteExistingMenu(Id bookingId) {

    List<ContentDocumentLink> links = [
        SELECT ContentDocumentId
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :bookingId
    ];

    Set<Id> docIds = new Set<Id>();

    for (ContentDocumentLink l : links) {
        docIds.add(l.ContentDocumentId);
    }

    delete [SELECT Id FROM ContentDocument WHERE Id IN :docIds];
}

/*    @AuraEnabled
public static Id uploadMenuFile(Id bookingId, String fileName, String base64Data) {

    Id networkId = Network.getNetworkId(); // 🔥 KEY

ContentVersion cv = new ContentVersion();
cv.Title = fileName;
cv.PathOnClient = fileName;
cv.File_Category__c = 'Menu';
cv.VersionData = EncodingUtil.base64Decode(base64Data);

// 🔥 ADD THIS LINE
if (networkId != null) {
    cv.NetworkId = networkId;
}

insert cv;

    // Get ContentDocumentId
    cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

    // Link to Booking
    ContentDocumentLink link = new ContentDocumentLink();
    link.ContentDocumentId = cv.ContentDocumentId;
    link.LinkedEntityId = bookingId;
    link.ShareType = 'V'; // ✅ correct
    insert link;


      return cv.ContentDocumentId; // ✅ return documentId
}*/

    @AuraEnabled
    public static String getFileDownloadUrl(Id contentDocumentId) {

        ContentVersion cv = [
            SELECT Id 
            FROM ContentVersion 
            WHERE ContentDocumentId = :contentDocumentId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        return '/sfc/servlet.shepherd/version/download/' + cv.Id;
    }

    @AuraEnabled(cacheable=true)
    public static String getProfileName() {
        return [
            SELECT Profile.Name 
            FROM User 
            WHERE Id = :UserInfo.getUserId()
        ].Profile.Name;
    }
}