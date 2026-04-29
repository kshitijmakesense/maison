import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getQuotes from '@salesforce/apex/CustomQuoteRelatedListController.getQuotes';

export default class CustomQuoteRelatedList extends NavigationMixin(LightningElement) {

    @api recordId; // parent record (Enquiry / Opportunity / Account)
    quotes;        // used in template (similar to your invoices example)
    error;

    columns = [
        {
            label: 'Quotient Quote Number',
            fieldName: 'quotientLink',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Quotient_Quote_Number__c' },
                target: '_blank'
            }
        },
        { label: 'Quote Name', fieldName: 'Name' },
        { label: 'Status', fieldName: 'Status' },
        {
            label: 'Total Price',
            fieldName: 'TotalPrice',
            type: 'currency',
            cellAttributes: { alignment: 'left' }
        },
        {
            label: 'Total Price Including Tax',
            fieldName: 'Total_Price_Including_Tax__c',
            type: 'currency',
            cellAttributes: { alignment: 'left' }
        }
    ];

    @wire(getQuotes, { parentId: '$recordId' })
    wiredQuotes({ error, data }) {
        if (data) {
            this.error = undefined;
            this.quotes = data.map(q => ({
                ...q,
                quotientLink: '/' + q.Id // clickable link label = Quotient Quote Number
            }));
        } else if (error) {
            this.error = error;
            this.quotes = undefined;
            // optional: console log
            // console.error('Error loading quotes:', error);
        }
    }
}