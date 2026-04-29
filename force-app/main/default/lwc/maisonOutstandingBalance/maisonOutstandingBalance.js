import { LightningElement, wire } from 'lwc';
import getOutstandingSummary
    from '@salesforce/apex/MaisonOutstandingBalanceService.getOutstandingSummary';
import outstandingIcon from '@salesforce/resourceUrl/OutstandingMark';

export default class MaisonOutstandingBalance extends LightningElement {

    totalAmount = 0;
    invoiceCount = 0;
    icon = outstandingIcon;

    @wire(getOutstandingSummary)
    wiredSummary({ data }) {
        if (data) {
            this.totalAmount = data.totalOutstanding;
            this.invoiceCount = data.invoiceCount;
        }
    }

    get formattedAmount() {
        return new Intl.NumberFormat('en-AU', {
            minimumFractionDigits: 1,
            maximumFractionDigits: 1
        }).format(this.totalAmount || 0);
    }
}