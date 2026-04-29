import { LightningElement, track } from 'lwc';
import getCurrentUserAccountId from '@salesforce/apex/CustomerPortalController.getCurrentUserAccountId';
import getAccountManager from '@salesforce/apex/AccountManagerController.getAccountManager';

export default class AccountManagerCard extends LightningElement {
    @track recordId;   // Account Id
    @track manager;

    connectedCallback() {
        this.loadAccount();
    }

    loadAccount() {
        getCurrentUserAccountId()
            .then(accId => {
                console.log('Fetched AccountId from Apex:', accId);
                this.recordId = accId;

                return getAccountManager({ accountId: this.recordId });
            })
            .then(result => {
                console.log('Manager:', result);
                this.manager = result;
            })
            .catch(error => {
                console.error('Error:', error);
            });
    }

    get hasManager() {
        return this.manager != null;
    }

    handleContact() {
        if (this.manager?.Email) {
            window.location.href = `mailto:${this.manager.Email}`;
        }
    }
}