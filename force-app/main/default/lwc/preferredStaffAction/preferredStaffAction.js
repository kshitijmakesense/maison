import { LightningElement, api } from 'lwc';
import addPreferredStaff from '@salesforce/apex/BookingPreferredStaffService.addPreferredStaff';
import removePreferredStaff from '@salesforce/apex/BookingPreferredStaffService.removePreferredStaff';
import isPreferredStaffAssigned from '@salesforce/apex/BookingPreferredStaffService.isPreferredStaffAssigned';

import { CloseActionScreenEvent } from 'lightning/actions';
import Toast from 'lightning/toast';

export default class PreferredStaffAction extends LightningElement {

    @api recordId;
    hasRun = false;

    renderedCallback() {
        if (this.recordId && !this.hasRun) {
            this.hasRun = true;
            this.execute();
        }
    }

    execute() {
        console.log('Running action for:', this.recordId);

        isPreferredStaffAssigned({ bookingId: this.recordId })
            .then(isAssigned => {
                return isAssigned
                    ? removePreferredStaff({ bookingId: this.recordId })
                    : addPreferredStaff({ bookingId: this.recordId });
            })
            .then(() => {
                Toast.show({
                    label: 'Success',
                    message: 'Preferred staff updated',
                    variant: 'success'
                });

                this.dispatchEvent(new CloseActionScreenEvent());

                setTimeout(() => {
                    window.location.reload();
                }, 500);
            })
            .catch(error => {
                console.error(error);

                Toast.show({
                    label: 'Error',
                    message: error?.body?.message || 'Error occurred',
                    variant: 'error'
                });

                this.dispatchEvent(new CloseActionScreenEvent());
            });
    }
}