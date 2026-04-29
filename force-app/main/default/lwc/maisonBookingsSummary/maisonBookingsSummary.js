import { LightningElement, wire } from 'lwc';
import getBookingSummary from '@salesforce/apex/MaisonBookingsSummaryController.getBookingSummary';

export default class MaisonBookingsSummary extends LightningElement {

    upcomingBookings = 0;
    totalGuests = 0;
    pastBookings = 0;
    totalBookedValue = 0;

    @wire(getBookingSummary)
    wiredSummary({ data, error }) {
        if (data) {
            this.upcomingBookings = data.upcomingBookings;
            this.totalGuests = data.totalGuests;
            this.pastBookings = data.pastBookings;
            this.totalBookedValue = data.totalBookedValue;
        } else if (error) {
            console.error('Booking summary error', error);
        }
    }

    get formattedValue() {
        return this.totalBookedValue?.toLocaleString('en-US', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        });
    }
}