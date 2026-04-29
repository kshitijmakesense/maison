import { LightningElement, wire } from 'lwc';
import getRecentInvoices from '@salesforce/apex/MaisonRecentInvoicesService.getRecentInvoices';
import { NavigationMixin } from 'lightning/navigation';
import getInvoiceSummary
    from '@salesforce/apex/MaisonRecentInvoicesService.getInvoiceSummary';
import outstandingIcon from '@salesforce/resourceUrl/OutstandingMark';



export default class MaisonRecentInvoices extends NavigationMixin(LightningElement) {

    invoices = [];
     outstandingIcon = outstandingIcon;
totalOutstanding = 0;
outstandingCount = 0;

@wire(getInvoiceSummary)
wiredSummary({ data }) {
    if (data) {
        this.totalOutstanding = data.totalOutstanding;
        this.outstandingCount = data.dueCount;
    }
}


    @wire(getRecentInvoices)
    wiredInvoices({ data }) {
        if (data) {
            this.invoices = data;
        }
    }

  
    viewInvoice(event) {
        const url = event.target.dataset.url;
        console.log('url: ' + url);
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

    get showOutstanding() {
    return this.totalOutstanding > 0;
}
get hasInvoices() {
    return this.invoices && this.invoices.length > 0;
}

}