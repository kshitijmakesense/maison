import { LightningElement, api, wire, track } from 'lwc';
import getInvoices from '@salesforce/apex/EnquiryInvoiceController.getInvoices';
import { NavigationMixin } from 'lightning/navigation';

export default class RelatedInvoices extends NavigationMixin(LightningElement) {

    @api recordId;
    @track invoices;
    @track error;

    columns = [
        {
            label: 'Xero Invoice Number',
            fieldName: 'invoiceUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Xero_Invoice_Number__c' },
                target: '_blank'
            }
        },
        { label: 'Invoice Date', fieldName: 'Invoice_Date__c', type: 'date' },
        { label: 'Payment Status', fieldName: 'Payment_Status__c', type: 'text' },
        { label: 'Amount', fieldName: 'Total_Amount__c', type: 'currency',
        cellAttributes: { alignment: 'left' } }
    ];

    @wire(getInvoices, { enquiryId: '$recordId' })
    wiredInvoices({ data, error }) {
        if (data) {
            // Add URL to each row
            this.invoices = data.map(row => ({
                ...row,
                invoiceUrl: '/' + row.Id
            }));
            this.error = null;
        } else if (error) {
            this.error = error;
            this.invoices = null;
        }
    }
}