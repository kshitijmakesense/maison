import { LightningElement, track } from 'lwc';
import getQuotes from '@salesforce/apex/QuotesController.getQuotes';
import { NavigationMixin } from 'lightning/navigation';
import getCurrentUserAccountId from '@salesforce/apex/CustomerPortalController.getCurrentUserAccountId';

export default class ProposalsQuotes extends NavigationMixin(LightningElement)
{

    @track quotes = [];
   

  @track showEmailModal = false;

   accountId;
   pageSize = 3;         // how many cards per page
currentPage = 1;
totalPages = 1;

@track paginatedQuotes = [];  // quotes to show on current page


handleSignClick() {
    this.showEmailModal = true;
}

closeModal() {
    this.showEmailModal = false;
}

openGmail() {
    window.open("https://mail.google.com", "_blank");
}

openOutlook() {
    window.open("https://outlook.live.com", "_blank");
}

openYahoo() {
    window.open("https://mail.yahoo.com", "_blank");
}

// This opens default email app on mobile/desktop
openMailApp() {
    window.location.href = "mailto:";
}


    connectedCallback() {
        this.loadQuotes();
    }

    loadQuotes() {
        getCurrentUserAccountId()
            .then(accId => {
                this.accountId = accId;
                return getQuotes({ accountId: accId });
            })
           .then(data => {
    const allQuotes = data.map(q => ({
        ...q,
        formattedInvestment: this.formatCurrency(q.totalInvestment),
        formattedCreated: this.formatDate(q.createdDate),
        formattedEvent: this.formatDate(q.eventDate),
        showSignButton: q.status === "Sent" || q.status === "Viewed"
    }));

    this.quotes = allQuotes;
    this.totalPages = Math.ceil(allQuotes.length / this.pageSize);
    this.updatePaginatedQuotes();
})

            .catch(error => {
                console.error('Error loading quotes:', error);
            });
    }

    updatePaginatedQuotes() {
    const start = (this.currentPage - 1) * this.pageSize;
    const end = start + this.pageSize;
    this.paginatedQuotes = this.quotes.slice(start, end);
}

handleNext() {
    if (this.currentPage < this.totalPages) {
        this.currentPage++;
        this.updatePaginatedQuotes();
    }
}

handlePrevious() {
    if (this.currentPage > 1) {
        this.currentPage--;
        this.updatePaginatedQuotes();
    }
}

handlePageClick(event) {
    const page = Number(event.target.dataset.page);
    this.currentPage = page;
    this.updatePaginatedQuotes();
}


    formatCurrency(amount) {
        if (!amount) return '$0';
        return new Intl.NumberFormat('en-AU', {
            style: 'currency',
            currency: 'AUD',
            minimumFractionDigits: 0
        }).format(amount);
    }

    formatDate(dt) {
        if (!dt) return '';
        return new Date(dt).toLocaleDateString('en-AU');
    }
getPageClass(pg) {
    return pg === this.currentPage
        ? "page-number active"
        : "page-number";
}
get isPrevDisabled() {
    return this.currentPage === 1;
}

get totalPagesArray() {
    const pages = [];
    for (let i = 1; i <= this.totalPages; i++) {
        pages.push({
            number: i,
            className: i === this.currentPage ? "page-number active" : "page-number"
        });
    }
    return pages;
}


get isNextDisabled() {
    return this.currentPage === this.totalPages;
}

    handleViewDetails(event) {
    const quoteId = event.target.dataset.id;

    this[NavigationMixin.Navigate]({
        type: "comm__namedPage",
        attributes: {
            name: "QuoteDetailsPage__c" // Replace with your page name
        },
        state: {
            id: quoteId,
        source: "proposals"
        }
    });
}

get totalPagesArray() {
    return Array.from({ length: this.totalPages }, (_, i) => i + 1);
}


}