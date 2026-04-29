public with sharing class AccountStaffController {

    @AuraEnabled(cacheable=true)
    public static List<StaffKpiWrapper> getStaffForAccount(Id accountId) {

        Map<Id, StaffKpiWrapper> staffKpiMap = new Map<Id, StaffKpiWrapper>();

        // 1. Get all Orders for this Account
        List<Order> orders = [
            SELECT Id, Order_Total_Amount__c
            FROM Order
            WHERE AccountId = :accountId
        ];

        if (orders.isEmpty()) {
            return new List<StaffKpiWrapper>();
        }

        // 2. Get all staff assignments for these orders
        List<Booking_Staff_Assignment__c> assignments = [
            SELECT Id,
                   Staff__c,
                   Staff__r.Name,
                   Staff__r.Role__c,
                   Staff__r.Group__c,
                   Booking_Order__c,
                   Booking_Order__r.Order_Total_Amount__c
            FROM Booking_Staff_Assignment__c
            WHERE Booking_Order__c IN :orders
        ];

        // 3. Build KPIs
        for (Booking_Staff_Assignment__c sa : assignments) {

            if (!staffKpiMap.containsKey(sa.Staff__c)) {
                staffKpiMap.put(
                    sa.Staff__c,
                    new StaffKpiWrapper(sa.Staff__c, sa.Staff__r.Name,sa.Staff__r.Role__c, sa.Staff__r.Group__c)
                );
            }

            StaffKpiWrapper kpi = staffKpiMap.get(sa.Staff__c);

            kpi.orderCount += 1;

            // add amount from the related Order
            kpi.totalAmount += (sa.Booking_Order__r.Order_Total_Amount__c != null)
                                ? sa.Booking_Order__r.Order_Total_Amount__c
                                : 0;
        }

        return staffKpiMap.values();
    }

    public class StaffKpiWrapper {
        @AuraEnabled public Id staffId;
        @AuraEnabled public String staffName;
        @AuraEnabled public String staffRole;
        @AuraEnabled public String staffGroup;
        @AuraEnabled public Integer orderCount = 0;
        @AuraEnabled public Decimal totalAmount = 0;

        public StaffKpiWrapper(Id staffId, String staffName, String staffRole, String staffGroup) {
            this.staffId = staffId;
            this.staffName = staffName;
            this.staffRole = staffRole;
            this.staffGroup = staffGroup;
        }
    }
}