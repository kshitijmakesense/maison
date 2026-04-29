// dynamicEnquiryBooking.js
import { LightningElement, track } from 'lwc';
import Id from '@salesforce/user/Id';
import checkUserProfile from '@salesforce/apex/DynamicEnquiryController.checkUserProfile';
import getRecordTypesForUser from '@salesforce/apex/DynamicEnquiryController.getRecordTypesForUser';
import getUserAccountId from '@salesforce/apex/DynamicEnquiryController.getUserAccountId';
import createEnquiryRecord from '@salesforce/apex/DynamicEnquiryController.createEnquiryRecord';
import getPicklistOptions from '@salesforce/apex/DynamicEnquiryController.getPicklistOptions';

export default class DynamicEnquiryBooking extends LightningElement {
    // CHANGE 1: Removed unnecessary flags - only keep what's needed for Community Users
    @track isLoading = false;
    @track showRecordTypeSelection = false;
    @track showEnquiryForm = false;
    @track hasProfileAccess = false; // TRUE only for Community Users with correct profile
    
    @track selectedRecordTypeId = '';
    @track selectedRecordTypeName = '';
    @track recordTypeOptions = [];
    @track userAccountId = '';
    @track userContactId = ''; // NEW: Store Contact ID
    
    // Form data
    @track formData = {};
    
    // Picklist options
    @track personalOrCorporateOptions = [];
    @track eventTypeOptions = [];
    @track priorityOptions = [];
    @track clientBriefOptions = [];
    @track uniformRequiredOptions = [];
    @track extraServicesOptions = [];
    @track budgetOptions = [];
    @track beverageOptions = [];
    
    userId = Id;

    connectedCallback() {
        this.initializeFormData();
        this.checkUserLoginStatus();
    }

    initializeFormData() {
        this.formData = {
            firstName: '',
            lastName: '',
            phoneNumber: '',
            emailAddress: '',
            eventDate: '',
            eventTime: '',
            occasion: '',
            personalOrCorporate: '',
            numberOfGuests: '',
            numberOfStaff: '',
            eventType: '',
            guestArrivalTime: '',
            venueAddress: '',
            guestDepartureTime: '',
            priority: '',
            clientBrief: '',
            uniformRequired: [],
            needExtraServices: [],
            doYouHaveBudget: '',
            estimatedBudget: '',
            specialRequirements: '',
            anythingElse: '',
            // Coffee Cart specific
            eventLocation: '',
            coffeeServiceStartTime: '',
            coffeeServiceEndTime: '',
            beveragesCoffeeType: [],
            cartArea: '',
            accessInstructions: '',
            setupBreakdown: '',
            brandingPreference: '',
            signageRequirement: '',
            coffeeCartBranded: false,
            additionalBeverages: '',
            specialRequests: '',
            specialityItems: '',
            eventLogoTheme: '' , // NEW: Event Logo/Theme field
            whatisthethemeorstyleoftheevent: ''
        };
    }

    // CHANGE 2: Simplified user check - only check profile for logged-in users
    checkUserLoginStatus() {
        this.isLoading = true;
        
        // Check if user is logged in (User ID starts with '005')
        if (this.userId && this.userId.startsWith('005')) {
            // User is logged in - check if they have the Community User profile
            this.checkUserProfile();
        } else {
            // Guest user or no user - hide everything by setting hasProfileAccess = false
            this.hasProfileAccess = false;
            this.isLoading = false;
        }
    }

    // CHANGE 3: Profile check determines if user sees the component
    checkUserProfile() {
        checkUserProfile({ userId: this.userId })
            .then(result => {
                this.hasProfileAccess = result.hasAccess;
                
                if (result.hasAccess) {
                    // User has 'Custom Customer Community User' profile
                    // Load data and show record type selection automatically
                    this.loadUserData();
                } else {
                    // User is logged in but doesn't have the correct profile
                    // Hide everything by keeping hasProfileAccess = false
                    this.isLoading = false;
                }
            })
            .catch(error => {
                // On error - hide everything
                console.error('Error checking profile:', error);
                this.hasProfileAccess = false;
                this.isLoading = false;
            });
    }

    // CHANGE 4: Only Community Users reach this method
    loadUserData() {
        Promise.all([
            getRecordTypesForUser(), // Get 4 record types
            getUserAccountId({ userId: this.userId }), // Get user's account and contact details
            getPicklistOptions() // Get picklist values
        ])
        .then(([recordTypes, userDetails, picklistData]) => {
            // Store record types for dropdown
            this.recordTypeOptions = recordTypes.map(rt => ({
                label: rt.Name,
                value: rt.Id,
                developerName: rt.DeveloperName
            }));
            
            // Store Account ID and Contact ID
            this.userAccountId = userDetails.accountId;
            this.userContactId = userDetails.contactId;
            
            // Auto-populate user details from Contact
            this.formData.firstName = userDetails.firstName || '';
            this.formData.lastName = userDetails.lastName || '';
            this.formData.emailAddress = userDetails.email || '';
            this.formData.phoneNumber = userDetails.phone || '';
            
            this.setPicklistOptions(picklistData);
            
            // Automatically show record type selection
            this.showRecordTypeSelection = true;
            this.isLoading = false;
        })
        .catch(error => {
            this.showToast('Error', this.getErrorMessage(error), 'error');
            this.isLoading = false;
        });
    }

    setPicklistOptions(picklistData) {
        this.personalOrCorporateOptions = this.formatPicklistOptions(picklistData.Personal_or_Corporate_Event__c);
        this.eventTypeOptions = this.formatPicklistOptions(picklistData.Event_Type__c);
        this.priorityOptions = this.formatPicklistOptions(picklistData.Priority__c);
        this.clientBriefOptions = this.formatPicklistOptions(picklistData.Client_Breif__c);
        this.uniformRequiredOptions = this.formatPicklistOptions(picklistData.Uniform_Required__c);
        this.extraServicesOptions = this.formatPicklistOptions(picklistData.Need_extra_services__c);
        this.budgetOptions = this.formatPicklistOptions(picklistData.Do_you_have_a_budget__c);
        this.beverageOptions = this.formatPicklistOptions(picklistData.Beverages_Coffee_Type__c);
    }

    formatPicklistOptions(picklistValues) {
        if (!picklistValues) return [];
        return picklistValues.map(item => ({
            label: item.label,
            value: item.value
        }));
    }

    handleRecordTypeChange(event) {
        this.selectedRecordTypeId = event.detail.value;
        const selected = this.recordTypeOptions.find(rt => rt.value === this.selectedRecordTypeId);
        this.selectedRecordTypeName = selected ? selected.developerName : '';
    }

    handleNext() {
        if (!this.selectedRecordTypeId) {
            this.showToast('Warning', 'Please select a service type', 'warning');
            return;
        }
        // Hide record type selection, show form
        this.showRecordTypeSelection = false;
        this.showEnquiryForm = true;
    }

    handleBack() {
        // Go back to record type selection
        this.showEnquiryForm = false;
        this.showRecordTypeSelection = true;
        this.resetForm();
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        this.formData[field] = event.target.value;
    }

    handleCheckboxChange(event) {
        const field = event.target.dataset.field;
        this.formData[field] = event.target.checked;
    }

    handleDualListChange(event) {
        const field = event.target.dataset.field;
        this.formData[field] = event.detail.value;
    }

    handleCancel() {
        // Return to record type selection and reset form
        this.showEnquiryForm = false;
        this.showRecordTypeSelection = true;
        this.resetForm();
    }

    handleSubmit() {
        if (!this.validateForm()) {
            this.showToast('Error', 'Please fill in all required fields correctly.', 'warning');
            return;
        }

        this.isLoading = true;
        const enquiryData = this.prepareEnquiryData();

        // CHANGE 5: Always pass recordTypeId (Community users always have selected record type)
        createEnquiryRecord({ 
            enquiryData: JSON.stringify(enquiryData),
            recordTypeId: this.selectedRecordTypeId,
            recordTypeName: this.selectedRecordTypeName
        })
            .then(result => {
                this.showToast('Success!', result.message || 'Your enquiry has been submitted successfully!', 'success');
                // After submission, return to record type selection
                this.showEnquiryForm = false;
                this.showRecordTypeSelection = true;
                this.resetForm();
            })
            .catch(error => {
                this.showToast('Submission Failed', this.getErrorMessage(error), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // CHANGE 6: Removed guest user logic - only Community users can submit
    prepareEnquiryData() {
        const data = {
            First_Name__c: this.formData.firstName,
            Last_Name__c: this.formData.lastName,
            Phone_Number__c: this.formData.phoneNumber,
            Email_Address__c: this.formData.emailAddress,
            Event_Date__c: this.formData.eventDate,
            Event_Time__c: this.formData.eventTime,
            Number_of_Guests__c: this.formData.numberOfGuests ? parseInt(this.formData.numberOfGuests) : null,
            Estimated_Budget__c: this.formData.estimatedBudget ? parseFloat(this.formData.estimatedBudget) : null,
            Venue_Address__c: this.formData.venueAddress,
            Name: this.generateEnquiryName(),
            StageName: 'New Enquiry',
            CloseDate: this.getDefaultCloseDate(),
            AccountId: this.userAccountId, // Always link to user's account
            Contact__c: this.userContactId // NEW: Link to user's contact
        };

        // Add record type specific fields
        if (this.isStandardLayout) {
            data.Occasion__c = this.formData.occasion;
            data.Personal_or_Corporate_Event__c = this.formData.personalOrCorporate;
            data.Number_of_Staff_Required__c = this.formData.numberOfStaff ? parseInt(this.formData.numberOfStaff) : null;
            data.Event_Type__c = this.formData.eventType;
            data.Guest_arrival_time__c = this.formData.guestArrivalTime;
            data.Guest_departure_time__c = this.formData.guestDepartureTime;
            data.Priority__c = this.formData.priority;
            data.Client_Breif__c = this.formData.clientBrief;
            data.Uniform_Required__c = this.formData.uniformRequired.join(';');
            data.Need_extra_services__c = this.formData.needExtraServices.join(';');
            data.Do_you_have_a_budget__c = this.formData.doYouHaveBudget;
            data.Special_Requirements__c = this.formData.specialRequirements;
            data.Anything_else_we_need_to_know__c = this.formData.anythingElse;
        }

        if (this.isCoffeeCartLayout) {
            //data.Event_Location__c = this.formData.eventLocation;
            data.Occasion__c = this.formData.occasion;
            data.Coffee_service_start_time__c = this.formData.coffeeServiceStartTime;
            data.Coffee_service_end_time__c = this.formData.coffeeServiceEndTime;
            data.Beverages_Coffee_Type__c = this.formData.beveragesCoffeeType.join(';');
            data.Guest_arrival_time__c = this.formData.guestArrivalTime;
            data.Cart_Area__c = this.formData.cartArea;
            data.Access_Instructions__c = this.formData.accessInstructions;
            data.Setup_Breakdown__c = this.formData.setupBreakdown;
            data.Branding_preference__c = this.formData.brandingPreference;
            data.Signage_requirement__c = this.formData.signageRequirement;
            data.Coffee_cart_to_be_branded_or_customized__c = this.formData.coffeeCartBranded;
            data.Additional_beverages_or_snacks__c = this.formData.additionalBeverages;
            data.Special_Requests__c = this.formData.specialRequests;
            data.Speciality_Items__c = this.formData.specialityItems;
            data.What_is_the_theme_or_style_of_the_event__c = this.formData.whatisthethemeorstyleoftheevent;
            
            // NEW: Only include Event Logo/Theme if checkbox is checked
            if (this.formData.coffeeCartBranded) {
                data.Event_Logo_Theme__c = this.formData.eventLogoTheme;
            }


        }

        return data;
    }

    validateForm() {
        const inputs = this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea, lightning-dual-listbox');
        let isValid = true;
        
        inputs.forEach(input => {
            if (input.checkValidity && !input.checkValidity()) {
                input.reportValidity();
                isValid = false;
            }
        });
        
        return isValid;
    }

    generateEnquiryName() {
        const firstName = this.formData.firstName || '';
        const lastName = this.formData.lastName || '';
        const date = this.formData.eventDate || new Date().toISOString().split('T')[0];
        const serviceName = this.selectedRecordTypeName.replace(/_/g, ' ') || 'Enquiry';
        return `${firstName} ${lastName} - ${serviceName} - ${date}`;
    }

    getDefaultCloseDate() {
        const today = new Date();
        today.setDate(today.getDate() + 30);
        return today.toISOString().split('T')[0];
    }

    resetForm() {

        // this.initializeFormData();
       // this.selectedRecordTypeId = '';
       // this.selectedRecordTypeName = '';

       // 1. Clear all form fields
        this.initializeFormData();
        
        // 2. Clear selected record type
        this.selectedRecordTypeId = '';
        this.selectedRecordTypeName = '';
        
        // 3. Hide form, show record type selection
        this.showEnquiryForm = false;
        this.showRecordTypeSelection = true;
        
        // 4. CRITICAL: Reload user data
        // This refreshes userAccountId and userContactId
        this.loadUserData();
    }

    showToast(title, message, variant) {
        const toastComponent = this.template.querySelector('c-toast-message');
        if (toastComponent) {
            toastComponent.show(title, message, variant);
        }
    }

    getErrorMessage(error) {
        if (error?.body?.message) {
            return error.body.message;
        } else if (error?.message) {
            return error.message;
        } else if (typeof error === 'string') {
            return error;
        }
        return 'An unexpected error occurred. Please try again or contact support.';
    }

    // Computed properties
    get formTitle() {
        if (this.showRecordTypeSelection) return 'Select Service Type';
        return `${this.selectedRecordTypeName.replace(/_/g, ' ')} Booking`;
    }

    get isNextDisabled() {
        return !this.selectedRecordTypeId;
    }

    // CHANGE 7: Only two layouts now - Standard and Coffee Cart (no guest layout)
    get isStandardLayout() {
        return this.showEnquiryForm && (
            this.selectedRecordTypeName === 'Sydney_Bookings' ||
            this.selectedRecordTypeName === 'Catering' ||
            this.selectedRecordTypeName === 'Melbourne_Bookings'
        );
    }

    get isCoffeeCartLayout() {
        return this.showEnquiryForm && this.selectedRecordTypeName === 'Coffee_Cart';
    }

    get showEventLogoField() {
    return this.isCoffeeCartLayout && this.formData.coffeeCartBranded === true;
    }

}