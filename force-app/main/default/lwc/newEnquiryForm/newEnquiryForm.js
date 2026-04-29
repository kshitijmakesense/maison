import { LightningElement, track, wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import createEnquiry from '@salesforce/apex/EnquiryController.createEnquiry';
import EVENT_TYPE_FIELD from '@salesforce/schema/Opportunity.Event_Type__c';

export default class NewEnquiryForm extends LightningElement {
    @track formData = {
        eventType: '',
        eventTitle: '',
        eventDate: '',
        eventTime: '',
        numberOfGuests: '',
        estimatedBudget: '',
        venueName: '',
        venueAddress: ''
    };

    @track isLoading = false;
    @track showForm = true;
    @track eventTypeOptions = [];

    // Fetch picklist values for Event Type field
    @wire(getPicklistValues, {
        recordTypeId: '012Bn000002IZNxIAO', // Master Record Type ID (works for all record types)
        fieldApiName: EVENT_TYPE_FIELD
    })
    wiredEventTypes({ error, data }) {
        if (data) {
            this.eventTypeOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            console.error('Error fetching event types:', error);
            this.showCustomToast(
                'Error',
                'Unable to load event types. Please refresh the page.',
                'error'
            );
        }
    }

    toggleForm() {
        this.showForm = !this.showForm;
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        this.formData[field] = event.target.value;
    }

    handleCancel() {
        this.resetForm();
        this.showForm = false;
    }

    handleSubmit() {
        if (!this.validateForm()) {
            this.showCustomToast(
                'Error', 
                'Please fill in all required fields correctly.', 
                'warning'
            );
            return;
        }

        this.isLoading = true;

        const enquiryData = {
            Event_Type__c: this.formData.eventType,
            Event_Title__c: this.formData.eventTitle,
            Event_Date__c: this.formData.eventDate,
            Event_Time__c: this.formData.eventTime,
            Number_of_Guests__c: this.formData.numberOfGuests ? parseInt(this.formData.numberOfGuests) : null,
            Estimated_Budget__c: this.formData.estimatedBudget ? parseFloat(this.formData.estimatedBudget) : null,
            Venue_Preference__c: this.formData.venueName,
            Venue_Address__c: this.formData.venueAddress,
            Name: this.generateEnquiryName(),
            StageName: 'New Enquiry',
            CloseDate: this.getDefaultCloseDate()
        };

        createEnquiry({ enquiryData })
            .then(result => {
                // Show success toast with the returned message
                const successMessage = result.message || 'Your enquiry has been submitted successfully!';
                this.showCustomToast('Success!', successMessage, 'success');
                
                // Reset form and hide it
                this.resetForm();
                this.showForm = false;
                
                // Optional: Log the record ID for debugging
                console.log('Created Enquiry Record ID:', result.recordId);
            })
            .catch(error => {
                // Show error toast with detailed message
                const errorMessage = this.getErrorMessage(error);
                this.showCustomToast('Submission Failed', errorMessage, 'error');
                
                // Log error for debugging
                console.error('Error creating enquiry:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    validateForm() {
        const inputs = this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea');
        let isValid = true;
        
        inputs.forEach(input => {
            if (!input.checkValidity()) {
                input.reportValidity();
                isValid = false;
            }
        });
        
        return isValid;
    }

    generateEnquiryName() {
        const title = this.formData.eventTitle || 'Event';
        const date = this.formData.eventDate || new Date().toISOString().split('T')[0];
        return `${title} - ${date}`;
    }

    getDefaultCloseDate() {
        const today = new Date();
        today.setDate(today.getDate() + 30);
        return today.toISOString().split('T')[0];
    }

    resetForm() {
        this.formData = {
            eventType: '',
            eventTitle: '',
            eventDate: '',
            eventTime: '',
            numberOfGuests: '',
            estimatedBudget: '',
            venueName: '',
            venueAddress: ''
        };
        
        // Clear validation errors
        const inputs = this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea');
        inputs.forEach(input => {
            input.value = '';
        });
    }

    showCustomToast(title, message, variant) {
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
}