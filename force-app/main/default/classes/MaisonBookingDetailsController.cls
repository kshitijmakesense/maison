public with sharing class MaisonBookingDetailsController {
    
    @AuraEnabled(cacheable=true)
    public static Order getOrderDetails(String recordId) {
        try {
            return [
                SELECT Id, 
                       OrderNumber, 
                       OpportunityId,
                       Opportunity.CreatedDate,
                       Staff_Names__c, 
                       Status,
                       Contact__c,
                       Contact__r.Phone,
                       Order_Total_Amount__c,
                       Personal_or_Corporate_Event__c,Event_Date__c,
                       Event_Type__c, 
                       Venue_Address__c, 
                       Occasion__c,
                       Number_of_Guests__c, 
                       Number_of_Staff_Required__c,
                       Menu_Details__c
                FROM Order 
                WHERE Id = :recordId 
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching order details: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Order_Line_Item__c> getOrderLineItems(String orderId) {
        try {
            return [
                SELECT Id,
                       Name,
                       Quantity__c,
                       Unit_Price__c,
                       Tax_Rate__c,
                       Tax_Amount__c,
                       Line_Total__c
                FROM Order_Line_Item__c
                WHERE Booking_Order__c = :orderId
                ORDER BY Name ASC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching order line items: ' + e.getMessage());
        }
    }
    
@AuraEnabled(cacheable=true)
public static List<StaffDTO> getStaffAssignments(Id orderId) {

    List<StaffDTO> result = new List<StaffDTO>();

    for (Booking_Staff_Assignment__c r : [
        SELECT Id,
               Staff__c,
               Staff__r.Name,
               Staff__r.Last_Name__c,
               Types_of_Staff__c
        FROM Booking_Staff_Assignment__c
        WHERE Booking_Order__c = :orderId
    ]) {

        StaffDTO dto = new StaffDTO();
        dto.id = r.Id;
        dto.staffFirstName = r.Staff__r.Name;
        dto.staffLastName = r.Staff__r.Last_Name__c;
        dto.staffType = r.Types_of_Staff__c;
        dto.photoUrl = getStaffPhotoUrl(r.Staff__c);

        result.add(dto);
    }

    return result;
}

    public class StaffDTO {
    @AuraEnabled public Id id;
    @AuraEnabled public String staffFirstName;
    @AuraEnabled public String staffLastName;
    @AuraEnabled public String staffType;
    @AuraEnabled public String photoUrl;
}
    
private static String getStaffPhotoUrl(Id staffId) {
    List<ContentDocumentLink> cdLinks = [
        SELECT ContentDocument.LatestPublishedVersionId
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :staffId
        ORDER BY ContentDocument.CreatedDate DESC
        LIMIT 1
    ];

    if (!cdLinks.isEmpty()) {
        return URL.getOrgDomainUrl().toExternalForm() +
            '/sfc/servlet.shepherd/version/download/' +
            cdLinks[0].ContentDocument.LatestPublishedVersionId;
    }

    return null;
}
    
    
    @AuraEnabled(cacheable=true)
    public static List<Quote> getQuotes(String orderId) {
        try {
            // First get the Order to retrieve OpportunityId
            Order orderRecord = [
                SELECT OpportunityId 
                FROM Order 
                WHERE Id = :orderId 
                LIMIT 1
            ];
            
            // If no opportunity found, return empty list
            if (orderRecord.OpportunityId == null) {
                return new List<Quote>();
            }
            
            // Get all Quotes associated with the Opportunity
            return [
                SELECT Id,
                       QuoteNumber,
                       Status,
                       ExpirationDate,
                       Total_Price_Including_Tax__c,
                       Opportunity.Occasion__c,
                       Opportunity.Venue_Address__c,
                       Quotient_Quote_URL__c,
                       OpportunityId
                FROM Quote
                WHERE OpportunityId = :orderRecord.OpportunityId
                ORDER BY CreatedDate DESC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching quotes: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getInvoices(String orderId) {
        try {
            // Step 1: Get the Order to retrieve OpportunityId and OrderNumber
            Order orderRecord = [
                SELECT OpportunityId, OrderNumber
                FROM Order 
                WHERE Id = :orderId 
                LIMIT 1
            ];
            
            // If no opportunity found, return empty result
            if (orderRecord.OpportunityId == null) {
                return new Map<String, Object>{
                    'invoices' => new List<Xero_Invoice__c>(),
                    'orderNumber' => orderRecord.OrderNumber
                };
            }
            
            // Step 2: Get all Quotes associated with the Opportunity
            List<Quote> quotes = [
                SELECT Id
                FROM Quote
                WHERE OpportunityId = :orderRecord.OpportunityId
            ];
            
            // If no quotes found, return empty result
            if (quotes.isEmpty()) {
                return new Map<String, Object>{
                    'invoices' => new List<Xero_Invoice__c>(),
                    'orderNumber' => orderRecord.OrderNumber
                };
            }
            
            // Extract Quote IDs
            Set<Id> quoteIds = new Set<Id>();
            for (Quote q : quotes) {
                quoteIds.add(q.Id);
            }
            
            // Step 3: Get all Invoices associated with these Quotes
            List<Xero_Invoice__c> invoices = [
                SELECT Id,
                       Xero_Invoice_Number__c,
                       Payment_Status__c,
                       CreatedDate,
                       Due_Date__c,
                       Total_Amount__c,
                       Xero_URL__c,
                       Quote__c,
                       Quote__r.Name,
                       Quote__r.Opportunity.Occasion__c,
                       Quote__r.OpportunityId
                FROM Xero_Invoice__c
                WHERE Quote__c IN :quoteIds
                ORDER BY CreatedDate DESC
            ];
            
            return new Map<String, Object>{
                'invoices' => invoices,
                'orderNumber' => orderRecord.OrderNumber
            };
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching invoices: ' + e.getMessage());
        }
    }
}