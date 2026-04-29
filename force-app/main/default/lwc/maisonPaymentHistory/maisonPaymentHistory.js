import { LightningElement, wire } from 'lwc';
import getPaymentHistory
    from '@salesforce/apex/MaisonPaymentHistoryService.getPaymentHistory';

export default class MaisonPaymentHistory extends LightningElement {

    payments = [];
    pageNumber = 1;
pageSize = 5;

totalRecords = 0;
totalPages = 1;

allPayments = [];

    @wire(getPaymentHistory)
wiredPayments({ data, error }) {
    if (data) {
        this.allPayments = data.map(p => ({
            ...p,
            dateFormatted: this.formatDate(p.paymentDate),
            amountFormatted: this.formatCurrency(p.amount)
        }));

        this.totalRecords = this.allPayments.length;
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize) || 1;

        this.pageNumber = 1;
        this.updatePagedData();
    } else if (error) {
        console.error('Payment history error', error);
    }
}

updatePagedData() {
    const start = (this.pageNumber - 1) * this.pageSize;
    const end = start + this.pageSize;

    this.payments = this.allPayments.slice(start, end);
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

    formatDate(value) {
        if (!value) return '';
        return new Intl.DateTimeFormat('en-AU', {
            day: '2-digit',
            month: 'short',
            year: 'numeric'
        }).format(new Date(value));
    }

    formatCurrency(value) {
        return new Intl.NumberFormat('en-AU', {
            minimumFractionDigits: 1,
            maximumFractionDigits: 1
        }).format(value || 0);
    }
}