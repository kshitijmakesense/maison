import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getUserDetails from '@salesforce/apex/UserDetailController.getUserDetails';

export default class UserDetail extends LightningElement {
    @api recordId;
    urlRecordId;
    userData;
    error;
    isLoading = false;

    // Wire the current page reference to get URL parameters
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.urlRecordId = currentPageReference.state?.recordId || 
                              currentPageReference.attributes?.recordId;
            
            // Load user data when recordId is available
            if (this.effectiveRecordId) {
                this.loadUserData();
            }
        }
    }

    get effectiveRecordId() {
        return this.recordId || this.urlRecordId;
    }

    // Load user data using Apex
    loadUserData() {
        if (!this.effectiveRecordId) {
            return;
        }

        this.isLoading = true;
        this.error = null;

        getUserDetails({ userId: this.effectiveRecordId })
            .then(result => {
                this.userData = result;
                this.error = null;
            })
            .catch(error => {
                this.error = error;
                this.userData = null;
                console.error('Error loading user details:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Getters for template
    get name() {
        return this.userData?.name || '';
    }

    get senderEmail() {
        return this.userData?.senderEmail || '';
    }

    get address() {
        return this.userData?.address || '';
    }

    get phone() {
        return this.userData?.phone || '';
    }

    get companyName() {
        return this.userData?.companyName || '';
    }

    get hasError() {
        return this.error != null;
    }

    get noRecordId() {
        return !this.effectiveRecordId;
    }

    get hasData() {
        return this.userData != null;
    }

    get errorMessage() {
        if (this.error) {
            return this.error.body?.message || this.error.message || 'Unknown error occurred';
        }
        return '';
    }

    // Watch for recordId changes
    @api
    connectedCallback() {
        if (this.effectiveRecordId) {
            this.loadUserData();
        }
    }

    // Refresh data
    handleRefresh() {
        this.loadUserData();
    }
}