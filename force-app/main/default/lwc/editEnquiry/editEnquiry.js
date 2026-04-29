import { LightningElement, track } from 'lwc';
import getEnquiryById from '@salesforce/apex/EnquiryDashboardController.getEnquiryById';
import updateEnquiry from '@salesforce/apex/EnquiryDashboardController.updateEnquiry';
import getPicklistOptions from '@salesforce/apex/DynamicEnquiryController.getPicklistOptions';
import { NavigationMixin } from 'lightning/navigation';
import { showToast } from 'c/globalToast';
import updateEnquiryRecord from '@salesforce/apex/EnquiryDashboardController.updateEnquiryRecord';

export default class EditEnquiry extends NavigationMixin(LightningElement) {
    @track enquiry = {};

    // Picklist options
    @track personalOrCorporateOptions = [];
    @track eventTypeOptions = [];
    @track priorityOptions = [];
    @track clientBriefOptions = [];
    @track uniformRequiredOptions = [];
    @track extraServicesOptions = [];
    @track budgetOptions = [];
    @track beverageOptions = [];

    recordId;

    connectedCallback() {
        const urlParams = new URLSearchParams(window.location.search);
        this.recordId = urlParams.get('recordId');

        // Load enquiry + picklists
        this.loadPicklists();
        this.loadEnquiry();
    }

    // Load all picklist option maps
    loadPicklists() {
        getPicklistOptions()
            .then(data => {
                this.setPicklistOptions(data);
            })
            .catch(error => {
                console.error('Picklist error:', error);
            });
    }

    // Format options into LWC-friendly { label, value }
    formatPicklistOptions(list) {
        if (!list) return [];
        return list.map(item => ({
            label: item.label,
            value: item.value
        }));
    }

    // Set all picklist variables
    setPicklistOptions(data) {
        this.personalOrCorporateOptions =
            this.formatPicklistOptions(data.Personal_or_Corporate_Event__c);

        this.eventTypeOptions =
            this.formatPicklistOptions(data.Event_Type__c);

        this.priorityOptions =
            this.formatPicklistOptions(data.Priority__c);

        this.clientBriefOptions =
            this.formatPicklistOptions(data.Client_Breif__c);

        this.uniformRequiredOptions =
            this.formatPicklistOptions(data.Uniform_Required__c);

        this.extraServicesOptions =
            this.formatPicklistOptions(data.Need_extra_services__c);

        this.budgetOptions =
            this.formatPicklistOptions(data.Do_you_have_a_budget__c);

        this.beverageOptions =
            this.formatPicklistOptions(data.Beverages_Coffee_Type__c);
    }

    // Load enquiry record
loadEnquiry() {
    getEnquiryById({ enquiryId: this.recordId })
        .then(res => {
            this.enquiry = { ...res };

            // Convert SF time → "HH:mm"
            this.enquiry.Coffee_service_start_time__c =
                this.formatTime(res.Coffee_service_start_time__c);

            this.enquiry.Coffee_service_end_time__c =
                this.formatTime(res.Coffee_service_end_time__c);

            // ❗ FIX: Convert "A;B;C" → ["A","B","C"]
            if (res.Beverages_Coffee_Type__c) {
                this.enquiry.Beverages_Coffee_Type__c =
                    res.Beverages_Coffee_Type__c.split(';');
            }
        })
        .catch(err => console.error(err));
}


formatTime(sfTime) {
    if (!sfTime) return null;

    // Salesforce returns milliseconds
    let ms = parseInt(sfTime, 10);

    let hours = Math.floor(ms / (1000 * 60 * 60));
    let minutes = Math.floor((ms % (1000 * 60 * 60)) / (1000 * 60));

    // Convert to 2-digit format HH:mm
    return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}`;
}

timeToMilliseconds(timeStr) {
    if (!timeStr) return null;
    const [hours, minutes] = timeStr.split(':');
    return (parseInt(hours) * 60 * 60 * 1000) + (parseInt(minutes) * 60 * 1000);
}

    // Update local state as fields change
    handleChange(e) {
        const field = e.target.dataset.field;
        this.enquiry[field] = e.target.value;
    }

    handleDualListChange(e) {
        const field = e.target.dataset.field;
        this.enquiry[field] = e.detail.value;
    }

   saveEnquiry() {
    if (Array.isArray(this.enquiry.Beverages_Coffee_Type__c)) {
        this.enquiry.Beverages_Coffee_Type__c =
            this.enquiry.Beverages_Coffee_Type__c.join(';');
    }

    const payload = JSON.stringify(this.enquiry);
    

    updateEnquiryRecord({
        enquiryData: payload,
        recordId: this.recordId,
        recordTypeName: this.enquiry.RecordType.DeveloperName
    })
        .then(res => {
            if (res.success) {
                showToast('Success', res.message, 'success');
                this.goBack();
            } else {
                showToast('Error', res.message, 'error');
            }
        })
        .catch(err => {
            console.error('Update error:', JSON.stringify(err));
            showToast('Error', 'Could not update enquiry', 'error');
        });
    }

    goBack() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Service_Requests__c' }
        });
    }

    get isCoffeeCart() {
        return this.enquiry?.RecordType?.DeveloperName === 'Coffee_Cart';
    }

    get isOtherType() {
        return !this.isCoffeeCart;
    }

     handleCheckboxChange(event) {
        const field = event.target.dataset.field;
        this.enquiry[field] = event.target.checked;
    }

    get showEventLogoField() {
    return this.isCoffeeCart && this.enquiry.Coffee_cart_to_be_branded_or_customized__c  === true;
    }
}