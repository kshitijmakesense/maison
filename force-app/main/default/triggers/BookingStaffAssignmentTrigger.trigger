trigger BookingStaffAssignmentTrigger on Booking_Staff_Assignment__c (after insert, after update, after delete, after undelete) {
    BookingStaffAssignmentHandler obj = new BookingStaffAssignmentHandler();
    obj.handler();
}