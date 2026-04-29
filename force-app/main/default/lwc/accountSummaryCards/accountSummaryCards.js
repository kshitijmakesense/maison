import { LightningElement, wire, track } from 'lwc';
import getAccountEventSummary from '@salesforce/apex/CustomerPortalController.getAccountEventSummary';

export default class AccountSummaryCards extends LightningElement {
    @track totalEvents;
    @track upcomingEvents = [];
    @track pendingQuotes;

    @wire(getAccountEventSummary)
    wiredSummary({ data, error }) {
        if (data) {
            this.totalEvents = data.totalEvents;
            this.pendingQuotes = data.pendingQuotes;
            this.upcomingEvents = data.upcomingEvents?.map(ev => ({
                Id: ev.Id,
                Name: ev.Name,
                EventTitle: ev.Event_Title__c,
                EventDate: new Date(ev.Event_Date__c).toLocaleDateString(),
                link: `/customers/s/order/${ev.Id}`
            }));
        } else if (error) {
            console.error(error);
        }
    }
}