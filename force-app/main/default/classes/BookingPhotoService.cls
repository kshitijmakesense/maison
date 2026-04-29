public without sharing class BookingPhotoService {
@AuraEnabled
public static List<Map<String, String>> getPhotos(Id bookingId) {

    List<Map<String, String>> result = new List<Map<String, String>>();

for (ContentDocumentLink cdl : [
    SELECT ContentDocumentId,
           ContentDocument.Title,
           ContentDocument.LatestPublishedVersionId
    FROM ContentDocumentLink
    WHERE LinkedEntityId = :bookingId
    ORDER BY ContentDocument.CreatedDate DESC
]) {

    // 🔥 get actual latest version
    ContentVersion cv = [
        SELECT Id, File_Category__c
        FROM ContentVersion
        WHERE Id = :cdl.ContentDocument.LatestPublishedVersionId
        LIMIT 1
    ];

    // 🔥 filter here instead
    if (cv.File_Category__c != 'Event Photo') continue;

    Map<String, String> photo = new Map<String, String>();
    photo.put('id', cdl.ContentDocumentId);
    photo.put('name', cdl.ContentDocument.Title);
    photo.put('versionId', cdl.ContentDocument.LatestPublishedVersionId);

    result.add(photo);
}

    return result;
}

@AuraEnabled
public static void updateFileAccess(List<Id> documentIds, Id recordId) {

    Id networkId = Network.getNetworkId();

    // 🔥 Update visibility
    List<ContentDocumentLink> links = [
        SELECT Id, ContentDocumentId
        FROM ContentDocumentLink
        WHERE ContentDocumentId IN :documentIds
        AND LinkedEntityId = :recordId
    ];

    for (ContentDocumentLink l : links) {
        l.Visibility = 'AllUsers';
    }
    update links;

    // 🔥 Update version (ADD CATEGORY HERE)
  List<ContentVersion> versions = new List<ContentVersion>();

for (Id docId : documentIds) {
    ContentVersion latest = [
        SELECT Id, NetworkId
        FROM ContentVersion
        WHERE ContentDocumentId = :docId
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];

    latest.NetworkId = networkId;
    latest.File_Category__c = 'Event Photo';

    versions.add(latest);
}

update versions;
}

@AuraEnabled
public static void uploadPhotos(Id bookingId, List<Map<String,String>> files) {

    Id networkId = Network.getNetworkId();

    List<ContentVersion> versions = new List<ContentVersion>();

    for (Map<String,String> file : files) {

        ContentVersion cv = new ContentVersion();
        cv.Title = file.get('fileName');
        cv.PathOnClient = file.get('fileName');
        cv.VersionData = EncodingUtil.base64Decode(file.get('base64'));

        cv.File_Category__c = 'Event Photo'; // 🔥 SET HERE (KEY FIX)

        if (networkId != null) {
            cv.NetworkId = networkId;
        }

        versions.add(cv);
    }

    insert versions;

    // 🔥 Link to booking
    List<ContentDocumentLink> links = new List<ContentDocumentLink>();

    for (ContentVersion cv : [
        SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :versions
    ]) {
        links.add(new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = bookingId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        ));
    }

    insert links;
}
    @AuraEnabled
    public static void deletePhoto(Id contentDocumentId) {

        delete [
            SELECT Id
            FROM ContentDocument
            WHERE Id = :contentDocumentId
        ];
    }
}