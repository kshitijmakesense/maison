import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/user/Id';

import checkUserProfile from '@salesforce/apex/DynamicEnquiryController.checkUserProfile';
import getUserAccountId from '@salesforce/apex/DynamicEnquiryController.getUserAccountId';
import getRecordTypesForUser from '@salesforce/apex/DynamicEnquiryController.getRecordTypesForUser';
import getPicklistOptions from '@salesforce/apex/DynamicEnquiryController.getPicklistOptions';
import createEnquiryRecord from '@salesforce/apex/DynamicEnquiryController.createEnquiryRecord';

export default class CoffeeCartQuickEnquiry extends NavigationMixin(LightningElement) {
    @track isLoading = false;
    @track hasProfileAccess = false;

    @track formData = {};
    @track beverageOptions = [];

    userId = Id;
    userAccountId;
    userContactId;

    coffeeCartRecordTypeId;
    coffeeCartRecordTypeName = 'Coffee_Cart';

    connectedCallback() {
        this.initializeFormData();
        this.checkUserAccess();
    }

    // -----------------------------
    // Init form
    // -----------------------------
    initializeFormData() {
        this.formData = {
            // Contact details (auto-filled from user)
            firstName: '',
            lastName: '',
            phoneNumber: '',
            emailAddress: '',

            // Event details
            eventDate: '',
            occasion: '',
            coffeeServiceStartTime: '',
            coffeeServiceEndTime: '',
            numberOfGuests: '',
            estimatedBudget: '',
            beveragesCoffeeType: [],
            guestArrivalTime: '',
            eventLocation: '',

            // Service & requirements
            coffeeCartBranded: false,
            eventLogoTheme: '',
            cartArea: '',
            setupBreakdown: '',
            brandingPreference: '',
            signageRequirement: '',
            accessInstructions: '',
            additionalBeverages: '',
            specialRequests: '',
            specialityItems: ''
        };
    }

    // -----------------------------
    // User & access
    // -----------------------------
    checkUserAccess() {
        this.isLoading = true;

        // If not a logged-in user (no 005...), don't show component
        if (!this.userId || !this.userId.startsWith('005')) {
            this.hasProfileAccess = false;
            this.isLoading = false;
            return;
        }

        checkUserProfile({ userId: this.userId })
            .then(res => {
                if (res.hasAccess) {
                    this.hasProfileAccess = true;
                    this.loadUserAndMetadata();
                } else {
                    this.hasProfileAccess = false;
                    this.isLoading = false;
                }
            })
            .catch(error => {
                console.error('Profile check error:', error);
                this.hasProfileAccess = false;
                this.isLoading = false;
            });
    }

    loadUserAndMetadata() {
        Promise.all([
            getUserAccountId({ userId: this.userId }),
            getRecordTypesForUser(),
            getPicklistOptions()
        ])
            .then(([userDetails, recordTypes, picklistData]) => {
                // User info
                this.userAccountId = userDetails.accountId;
                this.userContactId = userDetails.contactId;

                this.formData.firstName = userDetails.firstName || '';
                this.formData.lastName = userDetails.lastName || '';
                this.formData.emailAddress = userDetails.email || '';
                this.formData.phoneNumber = userDetails.phone || '';

                // Coffee Cart Record Type
                const coffee = recordTypes.find(rt => rt.DeveloperName === 'Coffee_Cart');
                if (coffee) {
                    this.coffeeCartRecordTypeId = coffee.Id;
                }

                // Picklists
                const bevList = picklistData.Beverages_Coffee_Type__c || [];
                this.beverageOptions = bevList.map(v => ({
                    label: v.label,
                    value: v.value
                }));

                this.isLoading = false;
            })
            .catch(error => {
                console.error('loadUserAndMetadata error:', error);
                this.showToast('Error', this.getErrorMessage(error), 'error');
                this.isLoading = false;
            });
    }

    // -----------------------------
    // Handlers
    // -----------------------------
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
        this.initializeFormData();
    }

    handleBack() {
        // Back to Quick Service Booking named page
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Quick_Service_Booking__c'
            }
        });
    }

    // -----------------------------
    // Submit
    // -----------------------------
    handleSubmit() {
        if (!this.validateForm()) {
            this.showToast('Error', 'Please fill in all required fields correctly.', 'error');
            return;
        }

        this.isLoading = true;
        const enquiryData = this.prepareEnquiryData();

        createEnquiryRecord({
            enquiryData: JSON.stringify(enquiryData),
            recordTypeId: this.coffeeCartRecordTypeId,
            recordTypeName: this.coffeeCartRecordTypeName
        })
            .then(result => {
                this.showToast('Success', result.message || 'Your enquiry has been submitted successfully!', 'success');
                this.initializeFormData();
            })
            .catch(error => {
                console.error('Submit error:', error);
                this.showToast('Error', this.getErrorMessage(error), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Build payload for Apex (matches DynamicEnquiryController.createEnquiryRecord)
    prepareEnquiryData() {
        const d = this.formData;

        const data = {
            // Common fields
            First_Name__c: d.firstName,
            Last_Name__c: d.lastName,
            Phone_Number__c: d.phoneNumber,
            Email_Address__c: d.emailAddress,
            Event_Date__c: d.eventDate,
            Number_of_Guests__c: d.numberOfGuests ? parseInt(d.numberOfGuests, 10) : null,
            Estimated_Budget__c: d.estimatedBudget ? parseFloat(d.estimatedBudget) : null,
            Venue_Address__c: d.eventLocation,
            Name: this.generateEnquiryName(),
            StageName: 'New Enquiry',
            CloseDate: this.getDefaultCloseDate(),
            AccountId: this.userAccountId,
            Contact__c: this.userContactId
        };

        // Coffee Cart–specific fields
        data.Event_Location__c = d.eventLocation;
        data.Occasion__c = d.occasion;
        data.Coffee_service_start_time__c = d.coffeeServiceStartTime;
        data.Coffee_service_end_time__c = d.coffeeServiceEndTime;
        data.Beverages_Coffee_Type__c = d.beveragesCoffeeType.join(';');
        data.Guest_arrival_time__c = d.guestArrivalTime; // "YYYY-MM-DDTHH:mm" → Apex handles
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

    generateEnquiryName() {
        const firstName = this.formData.firstName || '';
        const lastName = this.formData.lastName || '';
        const date = this.formData.eventDate || new Date().toISOString().split('T')[0];
        return `${firstName} ${lastName} - Coffee Cart - ${date}`;
    }

    getDefaultCloseDate() {
        const today = new Date();
        today.setDate(today.getDate() + 30);
        return today.toISOString().split('T')[0];
    }

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

    // Show logo field only when checkbox is checked
    get showEventLogoField() {
        return this.formData.coffeeCartBranded === true;
    }
}