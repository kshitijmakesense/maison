import { LightningElement, api, track } from 'lwc';
import getCurrentContactId from '@salesforce/apex/GetContactIdFromUser.getCurrentContactId';




export default class MaisonBookingsPage extends LightningElement {
    @track selectedRecordId = null;
    @track showDetailView = false;
    @track contactId;

    handleViewDetails(event) {
        this.selectedRecordId = event.detail.recordId;
        this.bookingType = event.detail.type;
        this.showDetailView = true;
    }

    handleBackToList() {
        this.showDetailView = false;
        this.selectedRecordId = null;
    }

    get showListView() {
        return !this.showDetailView;
    }

    connectedCallback() {
    getCurrentContactId()
        .then(result => {
            this.contactId = result;
        });
}
}