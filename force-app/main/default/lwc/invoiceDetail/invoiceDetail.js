import { LightningElement, api, wire, track } from 'lwc';
import getInvoice from '@salesforce/apex/InvoiceDetailController.getInvoice';
import { NavigationMixin, CurrentPageReference  } from 'lightning/navigation';

export default class InvoiceDetail extends NavigationMixin(LightningElement) {

    @api recordId;
    @track invoice;
    @track error;
    @track noInvoice = false;
    @track source;

    @wire(CurrentPageReference)
    getStateParameters(pageRef) {
        console.log('🌐 CurrentPageReference:', JSON.stringify(pageRef));
        if (pageRef && pageRef.state && pageRef.state.id) {
            this.recordId = pageRef.state.id;
            console.log('📌 Extracted recordId from URL state:', this.recordId);
        } else {
            console.log('⚠️ No id parameter found in URL state');
        }
          this.source = pageRef.state.source || 'default';
        console.log('📌 Source:', this.source);
    }

    @wire(getInvoice, { invoiceId: '$recordId' })
    wiredInvoice({ data, error }) {

        console.log('🔄 Wire fired for Invoice Detail');
        console.log('➡️ recordId received:', this.recordId);
        console.log('📦 Apex returned:', data);
        console.log('⚠️ Apex error:', error);

        if (data) {
            if (data.Id) {
                console.log('✅ Invoice found:', data.Id);
                this.invoice = data;
                this.noInvoice = false;
            } else {
                console.log('❗ No invoice returned (null or empty).');
                this.invoice = null;
                this.noInvoice = true;
            }
            this.error = null;
        } 
        else if (error) {
            console.log('❌ Error loading invoice:', error);
            this.error = error;
            this.invoice = null;
            this.noInvoice = false;
        }
    }

   /* navigateToRecord(event) {
        const recordId = event.currentTarget.dataset.id;
        console.log('🔗 Navigating to record:', recordId);

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }*/

     navigateToRecord(event) {
    const quoteId = this.invoice.Quote__c;

    this[NavigationMixin.Navigate]({
        type: "comm__namedPage",
        attributes: {
            name: "QuoteDetailsPage__c" // Replace with your page name
        },
        state: {
            id: quoteId,
        source: "invoiceDetail",
            invoiceId: this.recordId 
        }
    });
}

handleBack() {
    console.log("🔙 Back clicked. Source =", this.source);

    // 1️⃣ Coming from Recent Activity → Go Home
    if (this.source === 'recent') {
        this[NavigationMixin.Navigate]({
            type: "comm__namedPage",
            attributes: { name: "Home" }
        });
        return;
    }

     if (this.source === 'recentList') {
        this[NavigationMixin.Navigate]({
            type: "comm__namedPage",
            attributes: { name: "All_Recent_Activity__c" }
        });
        return;
    }

    // 2️⃣ Coming from Invoice List → back to invoice list page
    if (this.source === 'invoiceList') {
        this[NavigationMixin.Navigate]({
            type: "comm__namedPage",
            attributes: { name: "Invoices__c" }  // <--- your invoice list page API name
        });
        return;
    }

    // 3️⃣ Coming from Quote Details → back to quote details
   /* if (this.source === 'quoteDetail') {
        this[NavigationMixin.Navigate]({
            type: "comm__namedPage",
            attributes: { name: "QuoteDetailsPage__c" },
            state: {
                id: this.invoice.Quote__c
            }
        });
        return;
    }*/

    // 4️⃣ Default fallback → go Home
    this[NavigationMixin.Navigate]({
        type: "comm__namedPage",
        attributes: { name: "Home" }
    });
}

    get orderCreatedLabel() {
        if (!this.invoice) {
            return '';
        }
        const label = this.invoice.Order_Created__c ? 'Yes' : 'No';
        console.log('ℹ️ Order Created Label:', label);
        return label;
    }
}