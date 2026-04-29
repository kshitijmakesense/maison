import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getStaffForAccount from '@salesforce/apex/AccountStaffController.getStaffForAccount';

export default class StaffSection extends NavigationMixin(LightningElement) {
    @api recordId;
    @track data;
    @track error;

    @wire(getStaffForAccount, { accountId: '$recordId' })
    wiredStaff({ data, error }) {
        if (data) {
            this.data = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.data = undefined;
        }
    }

    get hasData() {
        return this.data && this.data.length > 0;
    }

    handleNavigate(event) {
        const staffId = event.currentTarget.dataset.id;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: staffId,
                objectApiName: 'Staff__c',
                actionName: 'view'
            }
        });
    }
}