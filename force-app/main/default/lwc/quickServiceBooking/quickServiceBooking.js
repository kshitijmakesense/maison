import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import coffeeLogo from '@salesforce/resourceUrl/coffee_cart_logo';

export default class QuickServiceBooking extends NavigationMixin(LightningElement) {
    coffeeLogo = coffeeLogo;
    handleOpenForm() {
        // Navigate to the dedicated Coffee Cart booking page
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Coffee_Cart_Booking__c' // this must match your Experience Builder page name
            }
        });
    }
}