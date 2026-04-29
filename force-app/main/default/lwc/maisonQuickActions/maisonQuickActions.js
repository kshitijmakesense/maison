import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class MaisonQuickActions extends NavigationMixin(
    LightningElement
) {

    // 🔒 Hardcoded Xero Payments URL
    XERO_PAYMENT_URL = 'https://go.xero.com';

    handleMakePayment() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: this.XERO_PAYMENT_URL
            }
        });
    }
}