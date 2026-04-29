public with sharing class AccountKpiController {

    @AuraEnabled(cacheable=true)
    public static KpiWrapper getAccountKpis(Id accountId) {
        KpiWrapper kpis = new KpiWrapper();

        // Total Enquiries (Opportunities)
        kpis.totalEnquiries = [
            SELECT COUNT()
            FROM Opportunity
            WHERE AccountId = :accountId
        ];

        // Total Orders
        kpis.totalOrders = [
            SELECT COUNT()
            FROM Order
            WHERE AccountId = :accountId
        ];

        // Total Revenue (Sum of Order Amount field)
        AggregateResult ar = [
            SELECT SUM(Order_Total_Amount__c) totalRevenue
            FROM Order
            WHERE AccountId = :accountId
        ];

        kpis.totalRevenue = (Decimal) ar.get('totalRevenue');

        // ⭐ Total Invoice Due (SUM of Xero Invoice Amount_Due__c)
        AggregateResult arInvoiceDue = [
            SELECT SUM(Amount_Due__c) totalDue
            FROM Xero_Invoice__c
            WHERE Account__c = :accountId
        ];
        kpis.totalInvoiceDue = (Decimal) arInvoiceDue.get('totalDue');

        return kpis;
    }

    public class KpiWrapper {
        @AuraEnabled public Integer totalEnquiries;
        @AuraEnabled public Integer totalOrders;
        @AuraEnabled public Decimal totalRevenue;
        @AuraEnabled public Decimal totalInvoiceDue;
    }
}