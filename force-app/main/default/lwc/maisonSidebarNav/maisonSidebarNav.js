import { LightningElement, api } from 'lwc';

export default class MaisonSidebarNav extends LightningElement {

    @api activePage = 'dashboard';

    handleNavClick(event) {
        const page = event.currentTarget.dataset.page;
        console.log('Navigating to:', page);
        this.dispatchEvent(
            new CustomEvent('navigate', {
                detail: { page },
                bubbles: true,
                composed: true
            })
        );
    }

    get isDashboard() {
        return this.activePage === 'dashboard';
    }

    get isQuotes() {
        return this.activePage === 'quotes';
    }

    get isInvoices() {
        return this.activePage === 'invoices';
    }

    get isBookings() {
    return this.activePage === 'bookings';
}

     get isPayments() {
        return this.activePage === 'payments';
    }

    /*get isReorder() {
    return this.activePage === 'reorder';
}

get reorderClass() {
    return `nav-item ${this.activePage === 'reorder' ? 'active' : ''}`;
}*/

    get dashboardClass() {
        return `nav-item ${this.isDashboard ? 'active' : ''}`;
    }

    get quotesClass() {
        return `nav-item ${this.activePage === 'quotes' ? 'active' : ''}`;
    }

    get bookingsClass() {
        return `nav-item ${this.activePage === 'bookings' ? 'active' : ''}`;
    }

    get invoicesClass() {
        return `nav-item ${this.activePage === 'invoices' ? 'active' : ''}`;
    }

    get paymentsClass() {
        return `nav-item ${this.activePage === 'payments' ? 'active' : ''}`;
    }
}