import { LightningElement, wire } from 'lwc';
import getUpcomingBookings from
    '@salesforce/apex/MaisonUpcomingBookingsService.getUpcomingBookings';
import getUpcomingBookingsCount
    from '@salesforce/apex/MaisonUpcomingBookingsService.getUpcomingBookingsCount';

export default class MaisonUpcomingBookings extends LightningElement {

    bookings = [];
     totalCount = 0;

    @wire(getUpcomingBookings)
    wiredBookings({ data }) {
        if (data) {
            this.bookings = data;
        }
    }



    @wire(getUpcomingBookingsCount)
    wiredCount({ data }) {
        if (data !== undefined) {
            this.totalCount = data;
             console.log('totalcount', this.totalCount);
        }
    }
   
    get hasBookings() {
    return this.bookings && this.bookings.length > 0;
}

}