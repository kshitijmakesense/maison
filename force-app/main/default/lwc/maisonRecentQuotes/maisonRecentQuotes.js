import { LightningElement, wire } from 'lwc';
import getRecentQuotes from '@salesforce/apex/MaisonRecentQuotesService.getRecentQuotes';
import getActiveQuoteCount from '@salesforce/apex/MaisonRecentQuotesService.getActiveQuoteCount';
import { NavigationMixin } from 'lightning/navigation';

export default class MaisonRecentQuotes extends NavigationMixin(LightningElement) {

    quotes = [];
     activeCount = 0;

    @wire(getRecentQuotes)
    wiredQuotes({ data }) {
        if (data) {
            this.quotes = data.map(q => ({
                ...q,
                isAccepted: q.status === 'Accepted'
            }));
        }
    }

      @wire(getActiveQuoteCount)
    wiredActiveCount({ data }) {
        if (data !== undefined) {
            this.activeCount = data;
        }
    }

    /*get activeCount() {
        return this.quotes.filter(q =>
            q.status === 'Sent' || q.status === 'Viewed'
        ).length;
    }*/

   viewQuote(event) {
    const url = event.target.dataset.url;

    if (!url) {
        console.error('Quote URL not available');
        return;
    }

    this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: {
            url: url
        }
    });
}

payQuote(event) {
    const url = event.target.dataset.url;
    console.log('xero url: ' + url);
    if (!url) {
        console.error('Xero URL not available');
        return;
    }

    this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: {
            url: url
        }
    });
}

get hasQuotes() {
    return this.quotes && this.quotes.length > 0;
}

}