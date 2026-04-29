import { LightningElement, wire } from 'lwc';
import getAllInvoices
    from '@salesforce/apex/MaisonAllInvoicesService.getAllInvoices';
import { NavigationMixin } from 'lightning/navigation';

export default class MaisonAllInvoices extends NavigationMixin(
    LightningElement
) {
    invoices = [];
    pageNumber = 1;
pageSize = 5;

totalRecords = 0;
totalPages = 0;

allInvoices = []; // store full data

 @wire(getAllInvoices)
wiredInvoices({ data }) {
    if (data) {
        this.allInvoices = data.map(inv => ({
            ...inv,
            relatedBookingDisplay: inv.relatedBooking ? inv.relatedBooking : 'No Booking',
            issueDateFormatted: this.formatDate(inv.issueDate),
            dueDateFormatted: this.formatDate(inv.dueDate),
            amountFormatted: this.formatCurrency(inv.amount),
            statusClass: this.getStatusClass(inv.status),
            statusIcon: this.getStatusIcon(inv.status),
            showIcon:
                inv.status === 'Paid' ||
                inv.status === 'Due Soon' ||
                inv.status === 'Partially Paid'
        }));

        this.totalRecords = this.allInvoices.length;
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize) || 1;

        this.pageNumber = 1; // reset
        this.updatePagedData();
    }
}

updatePagedData() {
    const start = (this.pageNumber - 1) * this.pageSize;
    const end = start + this.pageSize;

    this.invoices = this.allInvoices.slice(start, end);
}
handlePrevious() {
    if (this.pageNumber > 1) {
        this.pageNumber--;
        this.updatePagedData();
    }
}

handleNext() {
    if (this.pageNumber < this.totalPages) {
        this.pageNumber++;
        this.updatePagedData();
    }
}

get isPreviousDisabled() {
    return this.pageNumber === 1;
}

get isNextDisabled() {
    return this.pageNumber === this.totalPages;
}

get paginationInfo() {
    const start = (this.pageNumber - 1) * this.pageSize + 1;
    const end = Math.min(this.pageNumber * this.pageSize, this.totalRecords);
    return `Showing ${start}-${end} of ${this.totalRecords}`;
}

get pageInfo() {
    return `Page ${this.pageNumber} of ${this.totalPages}`;
}

get showPagination() {
    return this.totalRecords > this.pageSize;
}

/*formatDate(value) {
    if (!value) return '';
    return new Intl.DateTimeFormat('en-AU', {
        day: '2-digit',
        month: 'short',
        year: 'numeric'
    }).format(new Date(value));
}*/

formatDate(value) {
    if (!value) return '';
    return new Intl.DateTimeFormat('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric'
    }).format(new Date(value));
}

getStatusClass(status) {
    if (status === 'Paid') return 'status-pill paid';
    if (status === 'Partially Paid') return 'status-pill partial';
    return 'status-pill due';
}

getStatusIcon(status) {
    if (status === 'Paid') return '✔';
    if (status === 'Partially Paid') return '◐';
    if (status === 'Due Soon') return '⏱';
    return '';
}


    formatCurrency(value) {
        return new Intl.NumberFormat('en-AU', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(value || 0);
    }

   /* getStatusClass(status) {
        return `status-pill ${
            status === 'Paid' ? 'paid' : 'due'
        }`;
    }

    getStatusIcon(status) {
        if (status === 'Paid') return '✔';
        if (status === 'Due Soon') return '⏱';
        return '';
    }*/

    viewInvoice(event) {
       const url = event.target.dataset.url;
        if (!url) return;

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url }
        });
    }

    payInvoice(event) {
        const url = event.target.dataset.url;
        if (!url) return;

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url }
        });
    }

    get hasInvoices() {
    return this.invoices && this.invoices.length > 0;
}

}