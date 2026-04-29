import { LightningElement, track } from 'lwc';

export default class MaisonShellLayout extends LightningElement {

    @track activePage = 'dashboard';

    handleNavigate(event) {
        console.log('Shell received page:', event.detail.page);
        this.activePage = event.detail.page;
    }

    get isDashboard() {
        return this.activePage === 'dashboard';
    }
    get isQuotes() {
        return this.activePage === 'quotes';
    }
    get isBookings() {
        return this.activePage === 'bookings';
    }
    get isInvoices() {
        return this.activePage === 'invoices';
    }
    get isPayments() {
        return this.activePage === 'payments';
    }
    /*get isReorder() {
        return this.activePage === 'reorder';
    }*/
}