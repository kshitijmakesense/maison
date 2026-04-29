public without sharing class MaisonDashboardService {

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDashboardData() {

        Map<String, Object> result = new Map<String, Object>();

        // 1️⃣ Current User → Contact
        User u = [
            SELECT Id, ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        if (u.ContactId == null) return result;

        // 2️⃣ Contact → Account
        Contact c = [
            SELECT Id, AccountId
            FROM Contact
            WHERE Id = :u.ContactId
            LIMIT 1
        ];
        if (c.AccountId == null) return result;

        Id accId = c.AccountId;

        /* =====================================================
           ✅ 1. Active Quotes
        ===================================================== */
        Integer activeQuotes = [
            SELECT COUNT()
            FROM Quote
            WHERE AccountId = :accId
            AND Status IN ('Sent', 'Viewed')
        ];
        result.put('activeQuotes', activeQuotes);

        /* =====================================================
           ✅ 2. Upcoming Bookings
        ===================================================== */
        Integer upcomingBookings = [
            SELECT COUNT()
            FROM Order
            WHERE AccountId = :accId 
            AND Event_Date__c >= :Date.today()
            AND Status NOT IN ('Closed')
        ];
        result.put('upcomingBookings', upcomingBookings);

        /* =====================================================
           ✅ 3. Pending Invoices
        ===================================================== */
        Integer pendingInvoices = [
            SELECT COUNT()
            FROM Xero_Invoice__c
            WHERE Account__c = :accId
            AND Invoice_Status__c != 'Paid'
        ];
        result.put('pendingInvoices', pendingInvoices);

        /* =====================================================
           ✅ 4. Total Outstanding
        ===================================================== */
        AggregateResult ar = [
            SELECT SUM(Amount_Due__c) total
            FROM Xero_Invoice__c
            WHERE Account__c = :accId
            AND Invoice_Status__c != 'Paid'
        ];

        Decimal totalOutstanding = (Decimal) ar.get('total');
        result.put(
            'totalOutstanding',
            totalOutstanding == null ? 0 : totalOutstanding
        );

        return result;
    }
}