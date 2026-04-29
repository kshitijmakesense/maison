import { LightningElement, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import USER_ID from '@salesforce/user/Id';
import getAccountDetails from '@salesforce/apex/AccountHighlightController.getAccountDetails';
import basePath from '@salesforce/community/basePath';

const USER_FIELDS = ['User.AccountId'];

export default class AccountHighlightPanel extends NavigationMixin(LightningElement) {
    userId = USER_ID;
    @track accountId;
    @track orderCount = 0;
    @track enquiryCount = 0;
    
    @track error;
    @track isLoading = true;

    // Get the Account ID from the current user
    @wire(getRecord, { recordId: '$userId', fields: USER_FIELDS })
    wiredUser({ error, data }) {
        if (data) {
            this.accountId = data.fields.AccountId.value;
            if (this.accountId) {
                this.loadAccountDetails();
            } else {
                this.error = 'No account associated with this user';
                this.isLoading = false;
            }
        } else if (error) {
            this.error = 'Error retrieving user information';
            this.isLoading = false;
        }
    }

    // Load account details
    loadAccountDetails() {
        getAccountDetails({ accountId: this.accountId })
            .then(result => {
                this.orderCount = result.orderCount || 0;
                this.enquiryCount = result.enquiryCount || 0;
                this.error = undefined;
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error.body ? error.body.message : 'Error loading account details';
                this.isLoading = false;
            });
    }


    // Navigate to Order page
    handleOrderClick() {
        const baseUrl = basePath || '';
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: baseUrl + '/order'
            }
        });
    }

    // Navigate to Opportunity page
    handleEnquiryClick() {
        const baseUrl = basePath || '';
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: baseUrl + '/opportunity'
            }
        });
    }
}