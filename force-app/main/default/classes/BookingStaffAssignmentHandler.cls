public class BookingStaffAssignmentHandler {
    
    List<Booking_Staff_Assignment__c> triggerNew;
    List<Booking_Staff_Assignment__c> triggerOld;
    Map<Id, Booking_Staff_Assignment__c> triggerNewMap;
    Map<Id, Booking_Staff_Assignment__c> triggerOldMap;
    
    public BookingStaffAssignmentHandler() {
        triggerNew = (List<Booking_Staff_Assignment__c>)Trigger.new;
        triggerOld = (List<Booking_Staff_Assignment__c>)Trigger.old;
        triggerNewMap = (Map<Id, Booking_Staff_Assignment__c>)Trigger.newMap;
        triggerOldMap = (Map<Id, Booking_Staff_Assignment__c>)Trigger.oldMap;
    }
    
    public void handler() {
        switch on Trigger.operationType {
            when AFTER_INSERT {
                updateStaffNames(triggerNew);
            }
            when AFTER_UPDATE {
                updateStaffNames(triggerNew);
            }
            when AFTER_DELETE {
                updateStaffNames(triggerOld);
            }
            when AFTER_UNDELETE {
                updateStaffNames(triggerNew);
            }
        }
    }
    
    public void updateStaffNames(List<Booking_Staff_Assignment__c> assignmentList) {
        // 1. Collect unique parent Order (Booking) Ids
        Set<Id> orderIds = new Set<Id>();
        
        for(Booking_Staff_Assignment__c assignment : assignmentList) {
            if(assignment.Booking_Order__c != null) {
                orderIds.add(assignment.Booking_Order__c);
            }
        }
        
        // 2. Query all Booking Staff Assignments for these Orders with Staff details
        Map<Id, List<String>> staffNamesMap = new Map<Id, List<String>>();
        
        List<Booking_Staff_Assignment__c> assignmentsList = [
            SELECT Id, Booking_Order__c, Staff__r.Name 
            FROM Booking_Staff_Assignment__c 
            WHERE Booking_Order__c IN :orderIds
        ];
        
        // 3. Build map of Order Id to List of Staff Names
        for(Booking_Staff_Assignment__c assignment : assignmentsList) {
            if(!staffNamesMap.containsKey(assignment.Booking_Order__c)) {
                staffNamesMap.put(assignment.Booking_Order__c, new List<String>{assignment.Staff__r.Name});
            } else {
                staffNamesMap.get(assignment.Booking_Order__c).add(assignment.Staff__r.Name);
            }
        }
        
        // 4. Update Orders with concatenated Staff Names
        List<Order> ordersToUpdate = new List<Order>();
        
        for(Id orderId : orderIds) {
            Order orderRecord = new Order();
            orderRecord.Id = orderId;
            
            if(staffNamesMap.containsKey(orderId) && !staffNamesMap.get(orderId).isEmpty()) {
                orderRecord.Staff_Names__c = String.join(staffNamesMap.get(orderId), ', ');
            } else {
                orderRecord.Staff_Names__c = ''; // Clear field if no staff assigned
            }
            
            ordersToUpdate.add(orderRecord);
        }
        
        // 5. Perform DML operation
        if(!ordersToUpdate.isEmpty()) {
            update ordersToUpdate;
        }
    }
}