import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getFullQuoteDetails from '@salesforce/apex/QuotesControllerPortal.getFullQuoteDetails';

export default class QuoteDetails extends NavigationMixin(LightningElement) {

    @track quote;
    @track lineItems = [];
    error;
   @track invoiceId;

source;

   connectedCallback() {
    console.log("QuoteDetails LWC: connectedCallback fired");
     const url = new URL(window.location.href);
    const id = url.searchParams.get('id');
    const invoiceId = url.searchParams.get('invoiceId');
    console.log("QuoteDetails LWC: Quote Id =", id);
      console.log("QuoteDetails → invoiceId =", invoiceId);

    this.invoiceId = invoiceId; // store it
     this.source = url.searchParams.get("source") || "proposals";
    this.loadQuote(id);
}


    loadQuote(id) {
        getFullQuoteDetails({ quoteId: id })
            .then(res => {
                  console.log("QuoteDetails LWC: Apex returned =", JSON.stringify(res));
                this.quote = res.quote;
                this.lineItems = res.lineItems.map(li => ({
    ...li,
    formattedPrice: this.formatCurrency(li.UnitPrice),
    formattedSubtotal: this.formatCurrency(li.TotalPrice)
}));

            })
            .catch(err => {
                 console.error("QuoteDetails LWC ERROR:", err);
                this.error = err;
            });
    }

    renderedCallback() {
    console.log("QuoteDetails LWC: renderedCallback fired");
}


    get lineItemCount() {
        return this.lineItems.length;
    }

    formatCurrency(amount) {
        return new Intl.NumberFormat('en-AU', {
            style: 'currency',
            currency: 'AUD'
        }).format(amount);
    }

    handleBack() {
    if (this.source === "recentList") {
        this[NavigationMixin.Navigate]({
            type: "comm__namedPage",
            attributes: {
                name: "All_Recent_Activity__c"
            }
        });
    } else if (this.source === "recent"){
         this[NavigationMixin.Navigate]({
            type: "comm__namedPage",
            attributes: {
                name: "Home"
            }
        });
    } else if (this.source === "invoiceDetail") {
    this[NavigationMixin.Navigate]({
        type: "comm__namedPage",
        attributes: {
            name: "Invoice_Details__c"
        },
        state: {
            id: this.invoiceId
        }
    });
}

    else {
        this[NavigationMixin.Navigate]({
            type: "comm__namedPage",
            attributes: {
                name: "Proposals_and_Quotes__c"
            }
        });
    }
}



    get formattedTotal() {
        return this.formatCurrency(this.quote.TotalPrice);
    }

    get formattedTotalTax() {
        return this.formatCurrency(this.quote.Total_Price_Including_Tax__c);
    }

    get formattedSentDate() {
        return this.quote.Sent_Date__c ?
            new Date(this.quote.Sent_Date__c).toLocaleString('en-AU') : '';
    }

    get formattedExpiry() {
        return this.quote.ExpirationDate ?
            new Date(this.quote.ExpirationDate).toLocaleDateString('en-AU') : '';
    }
}