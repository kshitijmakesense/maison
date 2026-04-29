import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import userId from '@salesforce/user/Id';
import getAccountDetails from '@salesforce/apex/AccountInformationController.getAccountDetails';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';


export default class AccountInformation extends LightningElement {
    @track accountData = {};
    @track isLoading = true;
    @track currentPage = 1;
    totalPages = 2;
       @track displayBillingAddress = '';
       @track displayShippingAddress = '';
    accountId;
     isEditingCreditLimit = false;
     requestChangeMode = false;
    newCreditLimit;

  @track isToastVisible = false; // renamed from showToast
   @track toastTitle = '';
    @track toastMessage = '';
    @track toastVariant = 'success';

    @track bankNameOptions = [];

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    accountInfo;




    @wire(getAccountDetails, { userId: userId })
    wiredAccount({ error, data }) {
        if (data) {
            this.accountData = data;
            this.accountId = data.Id;
            this.displayBillingAddress = [
            data.BillingStreet,
            data.BillingCity,
            data.BillingState,
            data.BillingPostalCode,
            data.BillingCountry
        ].filter(part => part).join(', ');
            this.displayShippingAddress = [
            data.ShippingStreet,
            data.ShippingCity,
            data.ShippingState,
            data.ShippingPostalCode,
            data.ShippingCountry
            ].filter(part => part).join(', ');
            this.isLoading = false;
            console.log('Fetched accountData:', data);
        } else if (error) {
            console.error('Error in getAccountDetails:', error);
            this.showToast('Error', 'Failed to load account data', 'error');
            this.isLoading = false;
        }
    }

 
    get accountType() {
        return this.accountData.Type || 'N/A';
    }

    get industry() {
        return this.accountData.Industry || 'N/A';
    }

    
    // Page visibility getters
    get isPage1() {
        return this.currentPage === 1;
    }

    get isPage2() {
        return this.currentPage === 2;
    }

    // Button visibility getters
    get showPrevious() {
        return this.currentPage > 1;
    }

    get showNext() {
        return this.currentPage < this.totalPages;
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
        }
    }

    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }


   showCustomToast(title, message, variant) {
    this.toastTitle = title;
    this.toastMessage = message;
    this.toastVariant = variant; // e.g., 'success', 'error', 'warning', 'info'
    this.isToastVisible = true;

    // Auto-hide after 5 seconds (shorter)
    setTimeout(() => {
        this.isToastVisible = false;
    }, 5000);
}

handleToastClose() {
    this.isToastVisible = false;
}


 get toastClasses() {
    return `slds-notify slds-notify_toast slds-fade-in-open toast-container slds-theme_${this.toastVariant}`;
}




}