import { LightningElement, wire } from 'lwc';
import getOutstandingPayments
    from '@salesforce/apex/MaisonOutstandingPaymentsService.getOutstandingPayments';
import { NavigationMixin } from 'lightning/navigation';

export default class MaisonOutstandingPayments extends NavigationMixin(
    LightningElement
) {

    payments = [];
    pageNumber = 1;
pageSize = 5;

totalRecords = 0;
totalPages = 1;

allPayments = [];

  @wire(getOutstandingPayments)
wiredPayments({ data, error }) {
    if (data) {
        this.allPayments = data.map(p => ({
            ...p,
            amountFormatted: this.formatCurrency(p.amount),
            dueDateFormatted: this.formatDate(p.dueDate),

            buttonLabel: p.showPending
                ? 'Invoice Pending Approval'
                : (p.isOnCompletion ? 'Pay Early' : 'Pay Now'),

            buttonClass: p.showPending ? 'btn pending' : 'btn',
            isDisabled: p.showPending
        }));

        this.totalRecords = this.allPayments.length;
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize) || 1;

        this.pageNumber = 1;
        this.updatePagedData();
    } else if (error) {
        console.error('Apex error:', error);
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

    formatCurrency(value) {
        return new Intl.NumberFormat('en-AU', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(value || 0);
    }

    formatDate(value) {
        if (!value) return '';
        return new Intl.DateTimeFormat('en-AU', {
            day: '2-digit',
            month: 'short',
            year: 'numeric'
        }).format(new Date(value));
    }

    payNow(event) {
        const url = event.target.dataset.url;
        if (!url) return;

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url }
        });
    }
    get hasPayments() {
    return this.payments && this.payments.length > 0;
}

}