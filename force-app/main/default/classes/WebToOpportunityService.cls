@RestResource(urlMapping='/web/bookus')
global with sharing class WebToOpportunityService {

    global class BookingResponse {
        public Boolean success;
        public String message;
        public Id opportunityId;
    }

    @HttpPost
    global static BookingResponse createBookingEnquiry() {

        BookingResponse res = new BookingResponse();

        try {
            BookingRequest req = (BookingRequest)
                JSON.deserialize(RestContext.request.requestBody.toString(), BookingRequest.class);

            // Basic validation
            if (req.eventDate == null || String.isBlank(req.email)) {
                throw new AuraHandledException('Missing mandatory booking details');
            }

                 Opportunity opp = new Opportunity();

            // Mandatory field not handled by Flow
            opp.StageName = 'New Enquiry';

         
            // Basic Info
            opp.First_Name__c = req.firstName;
            opp.Last_Name__c  = req.lastName;
            opp.Phone_Number__c = req.phone;
            opp.Email_Address__c = req.email;

            // Event Details
            opp.Personal_or_Corporate_Event__c = req.personalOrCorporate;
            opp.Occasion__c = req.occasion;
            opp.Event_Type__c = req.eventType;
            opp.Event_Date__c = req.eventDate;
            opp.Guest_arrival_time__c = req.guestArrivalTime;
            opp.Guest_departure_time__c = req.guestDepartureTime;
            opp.Number_of_Guests__c = req.numberOfGuests;
            opp.Venue_Address__c = req.venueAddress;
            opp.Number_of_Staff_Required__c = req.numberOfStaffRequired;

            // Service & Requirements
            opp.Need_extra_services__c = req.needExtraServices;
            opp.Uniform_Required__c = req.uniformRequired;
            //opp.Client_Brief__c = req.clientBrief;
            opp.Special_Requirements__c = req.specialRequirements;
            opp.Estimated_Budget__c = req.estimatedBudget;

            insert opp;

            res.success = true;
            res.opportunityId = opp.Id;
            res.message = 'Booking enquiry created successfully';

        } catch (Exception e) {
            res.success = false;
            res.message = e.getMessage();
        }

        return res;
    }
}