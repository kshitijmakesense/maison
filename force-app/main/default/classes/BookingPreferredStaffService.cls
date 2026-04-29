public without sharing class BookingPreferredStaffService {

    @AuraEnabled
    public static Boolean isPreferredStaffAssigned(Id bookingId) {

        Id contactId = [
            SELECT Contact__c FROM Order WHERE Id = :bookingId
        ].Contact__c;

        Set<Id> preferredStaffIds = new Set<Id>();

        for (Preferred_Staff__c ps : [
            SELECT Preferred_Staff__c 
            FROM Preferred_Staff__c 
            WHERE Contact__c = :contactId
        ]) {
            preferredStaffIds.add(ps.Preferred_Staff__c);
        }

        Integer countRecords = [
            SELECT COUNT()
            FROM Booking_Staff_Assignment__c
            WHERE Booking_Order__c = :bookingId
            AND Staff__c IN :preferredStaffIds
        ];

        return countRecords > 0;
    }

    @AuraEnabled
    public static void addPreferredStaff(Id bookingId) {

        Order booking = [
            SELECT Contact__c FROM Order WHERE Id = :bookingId
        ];

        List<Preferred_Staff__c> prefs = [
            SELECT Preferred_Staff__c
            FROM Preferred_Staff__c
            WHERE Contact__c = :booking.Contact__c
        ];

        List<Booking_Staff_Assignment__c> toInsert = new List<Booking_Staff_Assignment__c>();

        for (Preferred_Staff__c ps : prefs) {
            toInsert.add(new Booking_Staff_Assignment__c(
                Booking_Order__c = bookingId,
                Staff__c = ps.Preferred_Staff__c
            ));
        }

        insert toInsert;
    }
@AuraEnabled
public static void removePreferredStaff(Id bookingId) {

    // 1️⃣ Get booking
    Order booking = [
        SELECT Id, Contact__c, Status
        FROM Order
        WHERE Id = :bookingId
    ];

    // 2️⃣ Get preferred staff ids
    Set<Id> preferredStaffIds = new Set<Id>();

    for (Preferred_Staff__c ps : [
        SELECT Preferred_Staff__c 
        FROM Preferred_Staff__c 
        WHERE Contact__c = :booking.Contact__c
    ]) {
        preferredStaffIds.add(ps.Preferred_Staff__c);
    }

    // 3️⃣ Get assignments to delete
    List<Booking_Staff_Assignment__c> toDelete = [
        SELECT Id
        FROM Booking_Staff_Assignment__c
        WHERE Booking_Order__c = :bookingId
        AND Staff__c IN :preferredStaffIds
    ];

    // 4️⃣ Delete staff
    if (!toDelete.isEmpty()) {
        delete toDelete;
    }

    // 5️⃣ Check if any staff still exists
    Integer remainingCount = [
        SELECT COUNT()
        FROM Booking_Staff_Assignment__c
        WHERE Booking_Order__c = :bookingId
    ];

    // 6️⃣ If no staff left → update status
    if (remainingCount == 0) {
        booking.Status = 'Invoice Paid';
        update booking;
    }
}

    @AuraEnabled
public static List<PreferredStaffDTO> getPreferredStaff(Id bookingId) {

    Order booking = [
        SELECT Contact__c FROM Order WHERE Id = :bookingId
    ];

    if (booking.Contact__c == null) {
        return new List<PreferredStaffDTO>();
    }

    List<PreferredStaffDTO> result = new List<PreferredStaffDTO>();

    for (Preferred_Staff__c ps : [
        SELECT Preferred_Staff__r.Name
        FROM Preferred_Staff__c
        WHERE Contact__c = :booking.Contact__c
    ]) {
        PreferredStaffDTO dto = new PreferredStaffDTO();
        dto.staffId = ps.Preferred_Staff__c;
        dto.staffName = ps.Preferred_Staff__r.Name;
        result.add(dto);
    }

    return result;
}

public class PreferredStaffDTO {
    @AuraEnabled public Id staffId;
    @AuraEnabled public String staffName;
}

}