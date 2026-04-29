import { LightningElement, track } from 'lwc';
import getInvoices from '@salesforce/apex/InvoiceListController.getInvoices';
import getCurrentUserAccountId from '@salesforce/apex/CustomerPortalController.getCurrentUserAccountId';
import { NavigationMixin } from 'lightning/navigation';

export default class InvoiceList extends NavigationMixin(LightningElement) {

    @track invoices = [];
    @track paginatedInvoices = [];
    @track noInvoices = false;

    pageSize = 3;
    currentPage = 1;
    totalPages = 1;
    accountId;

    connectedCallback() {
        console.log("🔄 InvoiceList connectedCallback fired");
        this.loadInvoices();
    }

    loadInvoices() {
        console.log("📡 Fetching current user AccountId...");

        getCurrentUserAccountId()
            .then(accId => {
                console.log("✅ AccountId retrieved:", accId);
                this.accountId = accId;

                console.log("📡 Fetching invoices for account:", accId);
                return getInvoices({ accountId: accId });
            })
            .then(data => {
                console.log("📦 Raw invoice data received:", JSON.stringify(data));

                if (!data || data.length === 0) {
                    console.log("ℹ️ No invoices found for this account.");
                    this.noInvoices = true;
                    return;
                }

                console.log("🔄 Processing invoice wrappers...");

                this.invoices = data.map(w => {
                    const inv = w.invoice;

                    console.log(`🧾 Mapping invoice: ${inv.Id}, Services: ${w.services}`);

                    return {
                        ...inv,
                        services: w.services,
                        formattedAmount: this.formatCurrency(inv.Total_Amount__c),
                        formattedIssued: this.formatDate(inv.Invoice_Date__c),
                        formattedDue: this.formatDate(inv.Due_Date__c),
                        statusClass: this.getStatusClass(inv.Payment_Status__c),
                        isPaid: inv.Payment_Status__c === 'Paid',
isOutstanding: inv.Payment_Status__c !== 'Paid'

                    };
                });

                this.totalPages = Math.ceil(this.invoices.length / this.pageSize);
                console.log(`📄 Total invoices: ${this.invoices.length}, Total pages: ${this.totalPages}`);

                this.updatePagination();
            })
            .catch(error => {
                console.error("❌ Error loading invoices:", error);
            });
    }

    getStatusClass(status) {
        console.log("🔍 Determining status class for:", status);
        return status === 'Paid' ? 'status-paid' : 'status-outstanding';
    }

    formatCurrency(amount) {
        console.log("💲 Formatting amount:", amount);
        if (!amount) return '$0';
        return new Intl.NumberFormat('en-AU', {
            style: 'currency',
            currency: 'AUD',
            minimumFractionDigits: 0
        }).format(amount);
    }

    formatDate(dt) {
        console.log("📅 Formatting date:", dt);
        if (!dt) return '';
        return new Date(dt).toLocaleDateString('en-AU');
    }

    updatePagination() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;

        console.log(`📑 Updating pagination → Page ${this.currentPage} (Items ${start} to ${end})`);

        this.paginatedInvoices = this.invoices.slice(start, end);
        console.log("📄 Paginated invoices:", this.paginatedInvoices);
    }

    handleNext() {
        console.log("➡️ Next page clicked");
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePagination();
        }
    }

    handlePrevious() {
        console.log("⬅️ Previous page clicked");
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePagination();
        }
    }

    handlePageClick(event) {
        const page = Number(event.target.dataset.page);
        console.log(`🔢 Page number clicked → Page ${page}`);
        this.currentPage = page;
        this.updatePagination();
    }

    // in InvoiceList.js
handleViewDetails(event) {
    const id = event.currentTarget.dataset.id;
    console.log("👁 View Details clicked for Invoice:", id);

    this[NavigationMixin.Navigate]({
        type: "comm__namedPage",
        attributes: {
            name: "Invoice_Details__c"   // ⚠️ must match the Experience Cloud named page API name
        },
        state: {
            id: id     ,
            source: "invoiceList"                  // we'll read this in InvoiceDetail
        }
    });
}


    handlePay(event) {
        const url = event.target.dataset.url;
        console.log("💳 Pay Now clicked → Opening URL:", url);

        window.open(url, "_blank");
    }

    get totalPagesArray() {
        console.log("🔢 Building page number array");
        return Array.from({ length: this.totalPages }, (_, i) => ({
            number: i + 1,
            className: i + 1 === this.currentPage ? "page-number active" : "page-number"
        }));
    }

    get isPrevDisabled() {
        return this.currentPage === 1;
    }

    get isNextDisabled() {
        return this.currentPage === this.totalPages;
    }
}