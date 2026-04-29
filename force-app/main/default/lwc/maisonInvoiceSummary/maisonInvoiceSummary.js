import { LightningElement, wire } from 'lwc';
import getInvoiceSummary
    from '@salesforce/apex/MaisonInvoiceSummaryService.getInvoiceSummary';

export default class MaisonInvoiceSummary extends LightningElement {

    summary = {
        pendingInvoices: 0,
        amountDue: 0,
        paidThisYear: 0,
        totalInvoices: 0
    };

    @wire(getInvoiceSummary)
    wiredSummary({ data }) {
        if (data) {
            this.summary = data;
        }
    }

    get formattedAmountDue() {
        return this.formatCurrency(this.summary.amountDue);
    }

    get formattedPaidThisYear() {
        return this.formatCurrency(this.summary.paidThisYear);
    }

    formatCurrency(value) {
        return new Intl.NumberFormat('en-AU', {
            minimumFractionDigits: 1,
            maximumFractionDigits: 1
        }).format(value || 0);
    }
}