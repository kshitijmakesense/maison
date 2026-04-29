import { LightningElement, api } from 'lwc';
import addPreferredStaff from '@salesforce/apex/BookingPreferredStaffService.addPreferredStaff';
import removePreferredStaff from '@salesforce/apex/BookingPreferredStaffService.removePreferredStaff';
import isPreferredStaffAssigned from '@salesforce/apex/BookingPreferredStaffService.isPreferredStaffAssigned';

import { CloseActionScreenEvent } from 'lightning/actions';
import Toast from 'lightning/toast';

export default class BookingPreferredStaffActionScreen extends LightningElement {

    @api recordId;

    handleClick() {
        console.log('CLICKED, recordId:', this.recordId);

        isPreferredStaffAssigned({ bookingId: this.recordId })
            .then(result => {
                if (result) {
                    return removePreferredStaff({ bookingId: this.recordId });
                } else {
                    return addPreferredStaff({ bookingId: this.recordId });
                }
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
                    message: error?.body?.message || 'Something went wrong',
                    variant: 'error'
                });
            });
    }
}