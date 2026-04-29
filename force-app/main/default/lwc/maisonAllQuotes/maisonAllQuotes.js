import { LightningElement } from 'lwc';
import getAllQuotes from '@salesforce/apex/MaisonAllQuotesService.getAllQuotes';
import { NavigationMixin } from 'lightning/navigation';

export default class MaisonAllQuotes extends NavigationMixin(LightningElement) {

    quotes = [];
    totalCount = 0;

    pageSize = 10;
    pageNumber = 1;

    connectedCallback() {
        this.loadQuotes();
    }

    loadQuotes() {
        getAllQuotes({
            pageSize: this.pageSize,
            pageNumber: this.pageNumber
        })
        .then(result => {
            this.quotes = result.records;
            this.totalCount = result.totalCount;
        })
        .catch(error => {
            console.error(error);
        });
    }

    // 🔥 PAGINATION HELPERS

    get totalPages() {
        return Math.ceil(this.totalCount / this.pageSize) || 1;
    }

    get isFirstPage() {
        return this.pageNumber === 1;
    }

    get isLastPage() {
        return this.pageNumber >= this.totalPages;
    }

    get showPagination() {
        return this.totalCount > this.pageSize;
    }

    get paginationInfo() {
        const start = (this.pageNumber - 1) * this.pageSize + 1;
        const end = Math.min(this.pageNumber * this.pageSize, this.totalCount);
        return `Showing ${start}-${end} of ${this.totalCount}`;
    }

    handleNext() {
        if (!this.isLastPage) {
            this.pageNumber++;
            this.loadQuotes();
        }
    }

    handlePrev() {
        if (!this.isFirstPage) {
            this.pageNumber--;
            this.loadQuotes();
        }
    }

    get isEmpty() {
        return !this.quotes || this.quotes.length === 0;
    }

    viewQuote(event) {
        const url = event.target.dataset.url;
        if (!url) return;

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url }
        });
    }

    payQuote(event) {
        const url = event.target.dataset.url;
        if (!url) return;

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url }
        });
    }
}