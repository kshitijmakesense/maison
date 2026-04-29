public with sharing class StaffKpiController {

    @AuraEnabled(cacheable=true)
    public static StaffKpiWrapper getStaffKpi(Id staffId) {
        StaffKpiWrapper result = new StaffKpiWrapper();

        // 1. Total Bookings - Count of all booking assignments for this staff
        result.totalBookings = [
            SELECT COUNT() 
            FROM Booking_Staff_Assignment__c
            WHERE Staff__c = :staffId
        ];

        // 2. Upcoming Events - Events with Event_Date__c >= TODAY
        result.upcomingEvents = [
            SELECT COUNT()
            FROM Booking_Staff_Assignment__c
            WHERE Staff__c = :staffId
            AND Booking_Order__r.Event_Date__c >= TODAY
        ];

        // 3. Completed Events - Events with Status = 'Completed'
        result.completedEvents = [
            SELECT COUNT()
            FROM Booking_Staff_Assignment__c
            WHERE Staff__c = :staffId
            AND Booking_Order__r.Status = 'Completed'
        ];

        // 4. Events This Month - Events where Event_Date__c is in current month
        Date firstDayOfMonth = Date.today().toStartOfMonth();
        Date lastDayOfMonth = firstDayOfMonth.addMonths(1).addDays(-1);
        
        result.eventsThisMonth = [
            SELECT COUNT()
            FROM Booking_Staff_Assignment__c
            WHERE Staff__c = :staffId
            AND Booking_Order__r.Event_Date__c >= :firstDayOfMonth
            AND Booking_Order__r.Event_Date__c <= :lastDayOfMonth
        ];

        // 5. Staff Photo - Get the first image attachment (JPEG or PNG)
        result.photoUrl = getStaffPhotoUrl(staffId);

        return result;
    }

    // Helper method to get staff photo URL from ContentDocumentLinks
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

    public class StaffKpiWrapper {
        @AuraEnabled public Integer totalBookings;
        @AuraEnabled public Integer upcomingEvents;
        @AuraEnabled public Integer completedEvents;
        @AuraEnabled public Integer eventsThisMonth;
        @AuraEnabled public String photoUrl;
    }
}