import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import Id from '@salesforce/user/Id';

import checkUserProfile from '@salesforce/apex/DynamicEnquiryController.checkUserProfile';
import getUserAccountId from '@salesforce/apex/DynamicEnquiryController.getUserAccountId';
import getPicklistOptions from '@salesforce/apex/DynamicEnquiryController.getPicklistOptions';
import getEnquiryForEdit from '@salesforce/apex/DynamicEnquiryController.getEnquiryForEdit';
import updateEnquiryRecord from '@salesforce/apex/EnquiryUpdateService.updateEnquiryRecordInternal';

export default class EditEnquiryRecord extends NavigationMixin(LightningElement) {
    @track isLoading = false;
    @track hasProfileAccess = false;
    @track isReadOnly = false;

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
    userAccountId;
    userContactId;

    recordId;
    recordTypeName; // DeveloperName

    initialized = false;

    source = 'service';


    // Get recordId from URL: /edit-enquiry?recordId=006.....
    @wire(CurrentPageReference)
getStateParameters(pageRef) {
    if (pageRef) {
        this.recordId = pageRef.state?.recordId;
        this.viewMode = pageRef.state?.mode || 'edit';
        this.isReadOnly = this.viewMode === 'view';
        this.source = pageRef.state?.source || 'service'; 

        if (this.recordId && !this.initialized) {
            this.initialized = true;
            this.initializeFormData();
            this.checkUserAccessAndLoad();
        }
    }
}


    initializeFormData() {
        this.formData = {
            // Common / contact-ish fields
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
            guestDepartureTime: '',
            venueAddress: '',
            priority: '',
            clientBrief: '',
            uniformRequired: [],
            needExtraServices: [],
            doYouHaveBudget: '',
            estimatedBudget: '',
            specialRequirements: '',
            anythingElse: '',
            // Coffee cart / shared
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
            eventLogoTheme: '',
            themeOrStyle: ''
        };
    }

    // --------------------- ACCESS & LOAD ---------------------

    checkUserAccessAndLoad() {
        this.isLoading = true;

        if (!this.userId || !this.userId.startsWith('005')) {
            this.hasProfileAccess = false;
            this.isLoading = false;
            return;
        }

        checkUserProfile({ userId: this.userId })
            .then(res => {
                if (res.hasAccess) {
                    this.hasProfileAccess = true;
                    return Promise.all([
                        getUserAccountId({ userId: this.userId }),
                        getPicklistOptions(),
                        getEnquiryForEdit({ recordId: this.recordId })
                    ]);
                } else {
                    this.hasProfileAccess = false;
                    this.isLoading = false;
                    return null;
                }
            })
            .then(results => {
                if (!results) return;

                const [userDetails, picklistData, enquiry] = results;

                this.userAccountId = userDetails.accountId;
                this.userContactId = userDetails.contactId;

                this.formData.firstName = userDetails.firstName || '';
                this.formData.lastName = userDetails.lastName || '';
                this.formData.emailAddress = userDetails.email || '';
                this.formData.phoneNumber = userDetails.phone || '';

                // Picklists
                this.setPicklistOptions(picklistData);

                // RecordType
                this.recordTypeName = enquiry.RecordType.DeveloperName;

                // Populate formData from existing Opportunity
                this.populateFormDataFromEnquiry(enquiry);

                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error during init:', error);
                this.showToast('Error', this.getErrorMessage(error), 'error');
                this.isLoading = false;
            });
    }

    setPicklistOptions(picklistData) {
        const fmt = list =>
            list ? list.map(item => ({ label: item.label, value: item.value })) : [];

        this.personalOrCorporateOptions = fmt(picklistData.Personal_or_Corporate_Event__c);
        this.eventTypeOptions = fmt(picklistData.Event_Type__c);
        this.priorityOptions = fmt(picklistData.Priority__c);
        this.clientBriefOptions = fmt(picklistData.Client_Breif__c);
        this.uniformRequiredOptions = fmt(picklistData.Uniform_Required__c);
        this.extraServicesOptions = fmt(picklistData.Need_extra_services__c);
        this.budgetOptions = fmt(picklistData.Do_you_have_a_budget__c);
        this.beverageOptions = fmt(picklistData.Beverages_Coffee_Type__c);
    }

    // --------------------- POPULATE EXISTING DATA ---------------------

    populateFormDataFromEnquiry(enq) {
        console.log('ENQUIRY FROM APEX >>> ', JSON.stringify(enq));

        // Common fields
        this.formData.eventDate = enq.Event_Date__c || '';
        this.formData.numberOfGuests = enq.Number_of_Guests__c != null ? String(enq.Number_of_Guests__c) : '';
        this.formData.estimatedBudget = enq.Estimated_Budget__c != null ? String(enq.Estimated_Budget__c) : '';
        this.formData.venueAddress = enq.Venue_Address__c || '';
        this.formData.eventType = enq.Event_Type__c || '';
        this.formData.occasion = enq.Occasion__c || '';

        // Event time (HH:mm)
        if (enq.Event_Time__c) {
           this.formData.eventTime = this.formatTimeField(enq.Event_Time__c);

        }

        // Datetime fields → "YYYY-MM-DDTHH:mm"
        if (enq.Guest_arrival_time__c) {
            this.formData.guestArrivalTime =
    this.formatDateTimeField(enq.Guest_arrival_time__c);
        }
        if (enq.Guest_departure_time__c) {
           this.formData.guestDepartureTime =
    this.formatDateTimeField(enq.Guest_departure_time__c);
        }

        // Standard layout
        this.formData.personalOrCorporate = enq.Personal_or_Corporate_Event__c || '';
        this.formData.numberOfStaff = enq.Number_of_Staff_Required__c != null ? String(enq.Number_of_Staff_Required__c) : '';
        this.formData.priority = enq.Priority__c || '';
        this.formData.clientBrief = enq.Client_Breif__c || '';
        this.formData.uniformRequired = enq.Uniform_Required__c ? enq.Uniform_Required__c.split(';') : [];
        this.formData.needExtraServices = enq.Need_extra_services__c ? enq.Need_extra_services__c.split(';') : [];
        this.formData.doYouHaveBudget = enq.Do_you_have_a_budget__c || '';
        this.formData.specialRequirements = enq.Special_Requirements__c || '';
        this.formData.anythingElse = enq.Anything_else_we_need_to_know__c || '';

        // Coffee cart–specific
        this.formData.eventLocation = enq.Event_Location__c || '';
        if (enq.Coffee_service_start_time__c) {
    console.log('RAW START TIME =>', JSON.stringify(enq.Coffee_service_start_time__c));
    this.formData.coffeeServiceStartTime =
        this.formatTimeField(enq.Coffee_service_start_time__c);
}

        if (enq.Coffee_service_end_time__c) {
    console.log('RAW END TIME =>', JSON.stringify(enq.Coffee_service_end_time__c));
    this.formData.coffeeServiceEndTime =
        this.formatTimeField(enq.Coffee_service_end_time__c);
}

        this.formData.beveragesCoffeeType = enq.Beverages_Coffee_Type__c ? enq.Beverages_Coffee_Type__c.split(';') : [];
        this.formData.cartArea = enq.Cart_Area__c || '';
        this.formData.accessInstructions = enq.Access_Instructions__c || '';
        this.formData.setupBreakdown = enq.Setup_Breakdown__c || '';
        this.formData.brandingPreference = enq.Branding_preference__c || '';
        this.formData.signageRequirement = enq.Signage_requirement__c || '';
        this.formData.coffeeCartBranded = enq.Coffee_cart_to_be_branded_or_customized__c || false;
        this.formData.additionalBeverages = enq.Additional_beverages_or_snacks__c || '';
        this.formData.specialRequests = enq.Special_Requests__c || '';
        this.formData.specialityItems = enq.Speciality_Items__c || '';
        this.formData.eventLogoTheme = enq.Event_Logo_Theme__c || '';
        this.formData.themeOrStyle = enq.What_is_the_theme_or_style_of_the_event__c || '';
    }

    // --------------------- HANDLERS ---------------------

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

   handleBack() {
    let pageName;

    if (this.source === 'recent') {
        pageName = 'Home';
    } else if(this.source === 'recentList'){
        pageName = 'All_Recent_Activity__c';
    }
        else {
        pageName = 'Service_Requests__c';
    }

    this[NavigationMixin.Navigate]({
        type: 'comm__namedPage',
        attributes: {
            name: pageName
        }
    });
}


    // --------------------- UPDATE ---------------------

    handleUpdate() {
        if (!this.validateForm()) {
            this.showToast('Error', 'Please fill in all required fields correctly.', 'error');
            return;
        }

        this.isLoading = true;
        const enquiryData = this.prepareEnquiryData();

        updateEnquiryRecord({
            enquiryData: JSON.stringify(enquiryData),
            recordId: this.recordId
        })
            .then(result => {
                if (result.success) {
                    this.showToast('Success', result.message, 'success');
                     // 🔥 Navigate back AFTER a small delay (ensures toast is visible)
                setTimeout(() => {
                    this.handleBack();
                }, 1000);
                } else {
                    this.showToast('Error', result.message, 'error');
                }
            })
            .catch(error => {
                console.error('Update error:', error);
                this.showToast('Error', this.getErrorMessage(error), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    prepareEnquiryData() {
        const d = this.formData;

        const data = {
            // Common fields
            First_Name__c: d.firstName,
            Last_Name__c: d.lastName,
            Phone_Number__c: d.phoneNumber,
            Email_Address__c: d.emailAddress,
            Event_Date__c: d.eventDate,
            Event_Time__c: d.eventTime,
            Number_of_Guests__c: d.numberOfGuests ? parseInt(d.numberOfGuests, 10) : null,
            Estimated_Budget__c: d.estimatedBudget ? parseFloat(d.estimatedBudget) : null,
            Venue_Address__c: d.venueAddress,
            // leave Name/StageName/CloseDate as-is or recompute if you want
        };

        if (this.isStandardLayout) {
            data.Occasion__c = d.occasion;
            data.Personal_or_Corporate_Event__c = d.personalOrCorporate;
            data.Number_of_Staff_Required__c = d.numberOfStaff ? parseInt(d.numberOfStaff, 10) : null;
            data.Event_Type__c = d.eventType;
            data.Guest_arrival_time__c = d.guestArrivalTime;
            data.Guest_departure_time__c = d.guestDepartureTime;
            data.Priority__c = d.priority;
            data.Client_Breif__c = d.clientBrief;
            data.Uniform_Required__c = d.uniformRequired.join(';');
            data.Need_extra_services__c = d.needExtraServices.join(';');
            data.Do_you_have_a_budget__c = d.doYouHaveBudget;
            data.Special_Requirements__c = d.specialRequirements;
            data.Anything_else_we_need_to_know__c = d.anythingElse;
        }

        if (this.isCoffeeCartLayout) {
            data.Event_Location__c = d.eventLocation;
            data.Occasion__c = d.occasion;
            data.Coffee_service_start_time__c = d.coffeeServiceStartTime;
            data.Coffee_service_end_time__c = d.coffeeServiceEndTime;
            data.Beverages_Coffee_Type__c = d.beveragesCoffeeType.join(';');
            data.Guest_arrival_time__c = d.guestArrivalTime;
            data.Cart_Area__c = d.cartArea;
            data.Access_Instructions__c = d.accessInstructions;
            data.Setup_Breakdown__c = d.setupBreakdown;
            data.Branding_preference__c = d.brandingPreference;
            data.Signage_requirement__c = d.signageRequirement;
            data.Coffee_cart_to_be_branded_or_customized__c = d.coffeeCartBranded;
            data.Additional_beverages_or_snacks__c = d.additionalBeverages;
            data.Special_Requests__c = d.specialRequests;
            data.Speciality_Items__c = d.specialityItems;
            data.What_is_the_theme_or_style_of_the_event__c = d.themeOrStyle;

            if (d.coffeeCartBranded) {
                data.Event_Logo_Theme__c = d.eventLogoTheme;
            }
        }

        return data;
    }

    validateForm() {
        const inputs = this.template.querySelectorAll(
            'lightning-input, lightning-combobox, lightning-textarea, lightning-dual-listbox'
        );
        let isValid = true;

        inputs.forEach(input => {
            if (input.reportValidity && !input.checkValidity()) {
                input.reportValidity();
                isValid = false;
            }
        });

        return isValid;
    }

    // --------------------- HELPERS ---------------------

    showToast(title, message, variant) {
        const toastComponent = this.template.querySelector('c-toast-message');
        if (toastComponent) {
            toastComponent.show(title, message, variant);
        }
    }

    getErrorMessage(error) {
        if (error?.body?.message) return error.body.message;
        if (error?.message) return error.message;
        if (typeof error === 'string') return error;
        return 'An unexpected error occurred.';
    }

    get formTitle() {
        return 'Edit Enquiry';
    }

    get isStandardLayout() {
        return (
            this.recordTypeName === 'Sydney_Bookings' ||
            this.recordTypeName === 'Catering' ||
            this.recordTypeName === 'Melbourne_Bookings'
        );
    }

    get isCoffeeCartLayout() {
        return this.recordTypeName === 'Coffee_Cart';
    }

    get showEventLogoField() {
        return this.isCoffeeCartLayout && this.formData.coffeeCartBranded === true;
    }

    formatDateTimeField(dt) {
    if (!dt) return '';

    // If it's already a string, normalize
    if (typeof dt === 'string') {
        return dt.replace(' ', 'T').substring(0, 16);
    }

    // If Apex sent a Date object (rare but possible in LWC)
    if (dt instanceof Date) {
        const yyyy = dt.getFullYear();
        const mm = String(dt.getMonth() + 1).padStart(2, '0');
        const dd = String(dt.getDate()).padStart(2, '0');
        const hh = String(dt.getHours()).padStart(2, '0');
        const min = String(dt.getMinutes()).padStart(2, '0');
        return `${yyyy}-${mm}-${dd}T${hh}:${min}`;
    }

    return '';
}

formatTimeField(timeVal) {
    if (!timeVal) return '';

    console.log('TIME VAL RECEIVED:', timeVal);

    // Case 1: Milliseconds after midnight (what Apex is sending)
    if (typeof timeVal === 'number') {
        const totalMs = timeVal;
        const totalSeconds = Math.floor(totalMs / 1000);
        const hh = String(Math.floor(totalSeconds / 3600)).padStart(2, '0');
        const mm = String(Math.floor((totalSeconds % 3600) / 60)).padStart(2, '0');
        return `${hh}:${mm}`;
    }

    // Case 2: Time string (rare)
    if (typeof timeVal === 'string') {
        return timeVal.substring(0, 5);
    }

    // Case 3: Time object (rare)
    if (typeof timeVal === 'object') {
        const hh = String(timeVal.hours).padStart(2, '0');
        const mm = String(timeVal.minutes).padStart(2, '0');
        return `${hh}:${mm}`;
    }

    return '';
}

get recordTypeLabel() {
    const map = {
        Sydney_Bookings: 'Sydney Booking',
        Melbourne_Bookings: 'Melbourne Booking',
        Catering: 'Catering',
        Coffee_Cart: 'Coffee Cart'
    };
    return map[this.recordTypeName] || this.recordTypeName;
}

get formContainerClass() {
    return this.isReadOnly ? 'read-only' : '';
}




}