import { LightningElement, api, track } from 'lwc';
import getPreferredStaff from '@salesforce/apex/BookingPreferredStaffService.getPreferredStaff';
import addPreferredStaff from '@salesforce/apex/BookingPreferredStaffService.addPreferredStaff';
import removePreferredStaff from '@salesforce/apex/BookingPreferredStaffService.removePreferredStaff';
import isPreferredStaffAssigned from '@salesforce/apex/BookingPreferredStaffService.isPreferredStaffAssigned';

import Toast from 'lightning/toast';
import { RefreshEvent } from 'lightning/refresh';

export default class BookingPreferredStaffPanel extends LightningElement {

    @api recordId;

    @track preferredStaffList = [];
    isAssigned = false;

    connectedCallback() {
        this.loadData();
    }

    loadData() {
        getPreferredStaff({ bookingId: this.recordId })
            .then(result => {
                this.preferredStaffList = result;
            });

        isPreferredStaffAssigned({ bookingId: this.recordId })
            .then(result => {
                this.isAssigned = result;
            });
    }

  get buttonLabel() {
        return this.isAssigned ? 'Remove Preferred Staff' : 'Add Preferred Staff';
    }

    get buttonClass() {
        return this.isAssigned ? 'remove-btn' : 'add-btn';
    }
    handleClick() {
        const action = this.isAssigned ? removePreferredStaff : addPreferredStaff;

        action({ bookingId: this.recordId })
            .then(() => {
                Toast.show({
                    label: 'Success',
                    message: 'Updated successfully',
                    variant: 'success'
                });

                this.loadData();

                // refresh related list
                this.dispatchEvent(new RefreshEvent());
            })
            .catch(error => {
                Toast.show({
                    label: 'Error',
                    message: error?.body?.message || 'Error',
                    variant: 'error'
                });
            });
    }
}