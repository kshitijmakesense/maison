import { LightningElement, wire } from 'lwc';
import getQuoteSummary
    from '@salesforce/apex/MaisonQuotesSummaryService.getQuoteSummary';

export default class MaisonQuotesSummary extends LightningElement {

    totalQuotes = 0;
    pendingReview = 0;
    accepted = 0;
    totalValue = 0;

    @wire(getQuoteSummary)
    wiredSummary({ data, error }) {
        if (data) {
            this.totalQuotes = data.totalQuotes;
            this.pendingReview = data.pendingReview;
            this.accepted = data.accepted;
            this.totalValue = data.totalValue;
        } else if (error) {
            console.error('Quote summary error', error);
        }
    }

    get formattedValue() {
        return this.totalValue?.toLocaleString();
    }
}