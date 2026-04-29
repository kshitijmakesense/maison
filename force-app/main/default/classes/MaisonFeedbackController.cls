public with sharing class MaisonFeedbackController {

    // ============================================
    // 🔹 FETCH EXISTING FEEDBACK
    // ============================================
    @AuraEnabled(cacheable=true)
    public static FeedbackWrapper getFeedback(Id bookingId) {

        Id contactId = [
            SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()
        ].ContactId;

        List<Feedback__c> records = [
            SELECT Id, Service__c, Food__c, Experience__c, Comments__c, Booking__c
            FROM Feedback__c
            WHERE Booking__c = :bookingId
            AND Contact__c = :contactId
            LIMIT 1
        ];

        if (!records.isEmpty()) {
            Feedback__c f = records[0];

            return new FeedbackWrapper(
    f.Id,
      f.Booking__c, 
    Integer.valueOf(f.Service__c),
    Integer.valueOf(f.Food__c),
    Integer.valueOf(f.Experience__c),
    f.Comments__c
);


        }

        return null;
    }

    // ============================================
    // 🔹 SAVE / UPDATE FEEDBACK
    // ============================================
   @AuraEnabled
public static void saveFeedback(String dataJson) {

    FeedbackWrapper data =
        (FeedbackWrapper) JSON.deserialize(dataJson, FeedbackWrapper.class);

    System.debug('🔥 bookingId: ' + data.bookingId); // debug

    Id contactId = [
        SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()
    ].ContactId;

    Feedback__c record;

    List<Feedback__c> existing = [
        SELECT Id
        FROM Feedback__c
        WHERE Booking__c = :data.bookingId
        AND Contact__c = :contactId
        LIMIT 1
    ];

    if (!existing.isEmpty()) {
        record = existing[0];
    } else {
        record = new Feedback__c(
            Booking__c = data.bookingId,   // ✅ now not null
            Contact__c = contactId
        );
    }

    record.Service__c = data.service;
    record.Food__c = data.food;
    record.Experience__c = data.experience;
    record.Comments__c = data.comments;

    upsert record;
}
    // ============================================
    // 🔹 WRAPPER
    // ============================================
    public class FeedbackWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public Id bookingId;
        @AuraEnabled public Integer service;
        @AuraEnabled public Integer food;
        @AuraEnabled public Integer experience;
        @AuraEnabled public String comments;

        public FeedbackWrapper() {}

       public FeedbackWrapper(Id id, Id bookingId, Integer service, Integer food, Integer experience, String comments) {
    this.id = id;
    this.bookingId = bookingId;
    this.service = service;
    this.food = food;
    this.experience = experience;
    this.comments = comments;
}
    }
}