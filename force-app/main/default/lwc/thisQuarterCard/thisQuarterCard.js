import { LightningElement, track } from 'lwc';
import getQuarterInsights from '@salesforce/apex/QuarterlyInsightController.getQuarterInsights';
import getCurrentUserAccountId from '@salesforce/apex/CustomerPortalController.getCurrentUserAccountId';

export default class ThisQuarterCard extends LightningElement {

    @track completed = 0;
    @track investment = 0;
    @track avgGuests = 0;
    @track trend = 0;

    connectedCallback() {
        this.loadInsights();
    }

    loadInsights() {
        getCurrentUserAccountId()
            .then(accId => {
                if (!accId) return;

                return getQuarterInsights({ accountId: accId });
            })
            .then(data => {
                if (!data) return;

                this.completed = data.completed;
                this.investment = data.investment;
                this.avgGuests = data.avgGuests;
                this.trend = data.trend;
            })
            .catch(error => console.error('Insight error → ', error));
    }
}