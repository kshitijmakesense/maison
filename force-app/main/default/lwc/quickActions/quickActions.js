import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class QuickActions extends NavigationMixin(LightningElement) {
    navigateToBook() {
        this[NavigationMixin.Navigate]({ type: 'standard__webPage', attributes: { url: '/book' } });
    }
    navigateToOrders() {
        this[NavigationMixin.Navigate]({ type: 'standard__webPage', attributes: { url: '/orders' } });
    }
    navigateToSupport() {
        this[NavigationMixin.Navigate]({ type: 'standard__webPage', attributes: { url: '/support' } });
    }
}