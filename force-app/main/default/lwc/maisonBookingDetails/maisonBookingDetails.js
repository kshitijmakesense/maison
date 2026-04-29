import { LightningElement, api, wire } from 'lwc';
import getOrderDetails from '@salesforce/apex/MaisonBookingDetailsController.getOrderDetails';
import getOrderLineItems from '@salesforce/apex/MaisonBookingDetailsController.getOrderLineItems';
import getStaffAssignments from '@salesforce/apex/MaisonBookingDetailsController.getStaffAssignments';
import getQuotes from '@salesforce/apex/MaisonBookingDetailsController.getQuotes';
import getInvoices from '@salesforce/apex/MaisonBookingDetailsController.getInvoices';

export default class MaisonBookingDetails extends LightningElement {
   _recordId;

@api
set recordId(value) {
    this._recordId = value;
    console.log('recordId received:', value);

    if (value) {
        this.loadStaffAssignments();
    }
}

get recordId() {
    return this._recordId;
}
    order;
    orderLineItems = [];
    staffAssignments = [];
    quotes = [];
    invoices = [];
    error;
    isLoading = true;
    @api bookingType;
    @wire(getOrderDetails, { recordId: '$recordId' })
    wiredOrder({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.order = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body?.message || 'An error occurred while loading order details';
            this.order = undefined;
        }
    }

 
    get isUpcoming() {
        return this.bookingType === 'UPCOMING';
    }

    get isPast() {
        return this.bookingType === 'PAST';
    }

    @wire(getOrderLineItems, { orderId: '$recordId' })
    wiredOrderLineItems({ error, data }) {
        if (data) {
            this.orderLineItems = data.map(item => ({
                ...item,
                formattedUnitPrice: this.formatCurrency(item.Unit_Price__c),
                formattedTaxRate: this.formatCurrency(item.Tax_Rate__c),
                formattedTaxAmount: this.formatCurrency(item.Tax_Amount__c),
                formattedLineTotal: this.formatCurrency(item.Line_Total__c)
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error.body?.message || 'An error occurred while loading order line items';
            this.orderLineItems = [];
        }
    }

 loadStaffAssignments() {
    getStaffAssignments({ orderId: this.recordId })
        .then(data => {
            console.log('STAFF DATA:', data);

           this.staffAssignments = data.map(staff => ({
    ...staff,
    initial: staff.staffFirstName
        ? staff.staffFirstName.charAt(0)
        : ''
}));
        })
        .catch(error => {
            console.error('STAFF ERROR:', error);
        });
}

    @wire(getQuotes, { orderId: '$recordId' })
    wiredQuotes({ error, data }) {
        if (data) {
            this.quotes = data.map(quote => ({
                ...quote,
                occasion: quote.Opportunity?.Occasion__c || '-',
                venue: quote.Opportunity?.Venue_Address__c || '-',
                quoteNumber: quote.QuoteNumber || '-',
                formattedExpirationDate: this.formatDate(quote.ExpirationDate),
                formattedAmount: this.formatCurrency(quote.Total_Price_Including_Tax__c),
                quoteUrl: quote.Quotient_Quote_URL__c || '#'
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error.body?.message || 'An error occurred while loading quotes';
            this.quotes = [];
        }
    }

    @wire(getInvoices, { orderId: '$recordId' })
    wiredInvoices({ error, data }) {
        if (data) {
            const invoiceList = data.invoices || [];
            const orderNumber = data.orderNumber || '-';
            
            this.invoices = invoiceList.map(invoice => ({
                ...invoice,
                invoiceNumber: invoice.Xero_Invoice_Number__c || '-',
                occasion: invoice.Quote__r?.Opportunity?.Occasion__c || '-',
                relatedBooking: orderNumber,
                formattedIssueDate: this.formatDate(invoice.CreatedDate),
                formattedDueDate: this.formatDate(invoice.Due_Date__c),
                formattedAmount: this.formatCurrency(invoice.Total_Amount__c),
                invoiceUrl: invoice.Xero_URL__c || '#'
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error.body?.message || 'An error occurred while loading invoices';
            this.invoices = [];
        }
    }

    formatCurrency(value) {
        if (value !== null && value !== undefined) {
            return '$' + Number(value).toFixed(2);
        }
        return '$0.00';
    }

    formatDate(dateValue) {
        if (!dateValue) return '-';
        
        const date = new Date(dateValue);
        const month = date.toLocaleString('en-US', { month: 'short' });
        const day = date.getDate();
        const year = date.getFullYear();
        const suffix = this.getDateSuffix(day);
        return `${month} ${day}${suffix}, ${year}`;
    }

    handleBack() {
        const backEvent = new CustomEvent('back', {
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(backEvent);
    }

    viewQuote(event) {
        const url = event.currentTarget.dataset.url;
        if (url && url !== '#') {
            window.open(url, '_blank');
        }
    }

    viewInvoice(event) {
        const url = event.currentTarget.dataset.url;
        if (url && url !== '#') {
            window.open(url, '_blank');
        }
    }

    get formattedEnquiryDate() {
        return this.formatDate(this.order?.Opportunity?.CreatedDate);
    }
get formattedEventDate() {
        return this.formatDate(this.order?.Event_Date__c);
    }


    getDateSuffix(day) {
        if (day >= 11 && day <= 13) {
            return 'th';
        }
        switch (day % 10) {
            case 1: return 'st';
            case 2: return 'nd';
            case 3: return 'rd';
            default: return 'th';
        }
    }

    get contactPhone() {
        return this.order?.Contact__r?.Phone || '-';
    }

  get menuDetails() {
    console.log('Menu:', this.order?.Menu_Details__c);
    return this.order?.Menu_Details__c;
}

get hasMenuDetails() {
    const val = this.order?.Menu_Details__c;
    return val && val.replace(/<[^>]*>/g, '').trim().length > 0;
}


    get formattedAmount() {
        return this.formatCurrency(this.order?.Order_Total_Amount__c);
    }

    get opportunityLink() {
        return this.order?.OpportunityId ? `/${this.order.OpportunityId}` : '#';
    }

    get personalOrCorporate() {
        return this.order?.Personal_or_Corporate_Event__c || '-';
    }

    get eventType() {
        return this.order?.Event_Type__c || '-';
    }

    get venueAddress() {
        return this.order?.Venue_Address__c || '-';
    }

    get occasion() {
        return this.order?.Occasion__c || '-';
    }

    get numberOfGuests() {
        return this.order?.Number_of_Guests__c || '-';
    }

    get numberOfStaff() {
        return this.order?.Number_of_Staff_Required__c || '-';
    }
}