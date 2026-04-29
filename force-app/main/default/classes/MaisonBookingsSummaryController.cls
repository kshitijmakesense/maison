public with sharing class MaisonBookingsSummaryController {
    
    @AuraEnabled(cacheable=true)
    public static BookingSummary getBookingSummary() {
        try {
            BookingSummary summary = new BookingSummary();
            Date today = Date.today();
            
            // Get current user's AccountId
            Id accountId = getCurrentUserAccountId();
            
            // If no AccountId found, return empty summary
            if (accountId == null) {
                return summary;
            }
            
            // Get orders filtered by the user's AccountId
            List<Order> orders = [
                SELECT Id, AccountId, Event_Date__c, Number_of_Guests__c, Status, TotalAmount, Event_Outcome__c,Order_Total_Amount__c
                FROM Order
                WHERE Event_Date__c != null
                AND AccountId = :accountId
            ];
            
            Decimal totalGuestsCount = 0;
            Decimal totalBookedValue = 0;
            
            for (Order ord : orders) {
                // 1. Upcoming Bookings - Event date is today or in the future
                if (ord.Event_Date__c >= today) {
                    summary.upcomingBookings++;
                    
                    // 2. Total Guests - Sum guests for upcoming events
                    if (ord.Number_of_Guests__c != null) {
                        totalGuestsCount += ord.Number_of_Guests__c;
                    }
                }
                
                // 3. Past Bookings - Event date is in the past (not including today) and status is closed
                if (ord.Event_Date__c < today && 
                    (ord.Status == 'Closed' || ord.Status == 'Activated')) {
                    summary.pastBookings++;
                }
                
                // 4. Total Booked Value - Sum of all TotalAmount
                if (ord.Order_Total_Amount__c != null) {
                    totalBookedValue += ord.Order_Total_Amount__c;
                }
            }
            
            summary.totalGuests = Integer.valueOf(totalGuestsCount);
            summary.totalBookedValue = totalBookedValue;
            
            return summary;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching booking summary: ' + e.getMessage());
        }
    }
    
    // Helper method to get current user's AccountId
    private static Id getCurrentUserAccountId() {
        try {
            // Get current user's ContactId
            User currentUser = [
                SELECT ContactId
                FROM User
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];
            
            // If user has no ContactId (internal user), return null
            if (currentUser.ContactId == null) {
                return null;
            }
            
            // Get AccountId from Contact
            Contact userContact = [
                SELECT AccountId
                FROM Contact
                WHERE Id = :currentUser.ContactId
                LIMIT 1
            ];
            
            return userContact.AccountId;
            
        } catch (Exception e) {
            // Return null if any error occurs
            return null;
        }
    }
    
    // Wrapper class for the summary data
    public class BookingSummary {
        @AuraEnabled public Integer upcomingBookings { get; set; }
        @AuraEnabled public Integer totalGuests { get; set; }
        @AuraEnabled public Integer pastBookings { get; set; }
        @AuraEnabled public Decimal totalBookedValue { get; set; }
        
        public BookingSummary() {
            this.upcomingBookings = 0;
            this.totalGuests = 0;
            this.pastBookings = 0;
            this.totalBookedValue = 0;
        }
    }
}