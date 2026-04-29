import { LightningElement, api, wire } from 'lwc';
import getAccountKpis from '@salesforce/apex/AccountKpiController.getAccountKpis';

export default class AccountKpiCards extends LightningElement {
    @api recordId;
    data;
    error;

    @wire(getAccountKpis, { accountId: '$recordId' })
    wiredKpis({ data, error }) {
        if (data) {
            this.data = data;
            this.error = undefined;
        } else {
            this.error = error;
            this.data = undefined;
        }
    }

    get formattedRevenue() {
    if (!this.data || this.data.totalRevenue == null) {
        return '$0.00';
    }

    return new Intl.NumberFormat('en-AU', { 
        style: 'currency', 
        currency: 'AUD' 
    }).format(this.data.totalRevenue);
}

get formattedInvoiceDue() {
    if (!this.data || this.data.totalInvoiceDue == null) {
        return '$0.00';
    }

    return new Intl.NumberFormat('en-AU', { 
        style: 'currency', 
        currency: 'AUD' 
    }).format(this.data.totalInvoiceDue);
}


}