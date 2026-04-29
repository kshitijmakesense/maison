import { LightningElement, track, wire } from 'lwc';
import getUpcomingEvents from '@salesforce/apex/MaisonUpcomingEventController.getUpcomingEvents';

export default class MaisonUpcomingEvent extends LightningElement {
    @track allEvents = [];
    @track displayedEvents = [];
    @track currentPage = 1;
    @track totalPages = 1;
    pageSize = 5;
    error;

    @wire(getUpcomingEvents)
    wiredEvents({ error, data }) {
        console.log('📌 wiredEvents triggered');

        if (data) {
            console.log('✅ Raw Events Data:', JSON.parse(JSON.stringify(data)));

            this.allEvents = data.map(event => {
                const mappedEvent = {
                    ...event,
                    formattedDate: this.formatDate(event.Event_Date__c),
                    formattedAmount: this.formatCurrency(event.Order_Total_Amount__c),
                    venueLines: this.splitVenueAddress(event.Venue_Address__c),
                    statusClass: this.getStatusClass(event.Status)
                };

                console.log('🧩 Mapped Event:', mappedEvent);
                return mappedEvent;
            });

            this.totalPages = Math.ceil(this.allEvents.length / this.pageSize);
            console.log('📄 Total Pages:', this.totalPages);

            this.updateDisplayedEvents();
            this.error = undefined;

        } else if (error) {
            console.error('❌ Error fetching events:', error);
            this.error = error;
            this.allEvents = [];
        }
    }

    getStatusClass(status) {
        if (!status) return 'default';
        const statusLower = status.toLowerCase().replace(/\s+/g, '-');
        console.log('🎯 Status Class:', statusLower);
        return statusLower;
    }

    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        const formatted = date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
        console.log('📅 Formatted Date:', formatted);
        return formatted;
    }

    formatCurrency(amount) {
        if (!amount) return '$0.00';
        const formatted = new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(amount);
        console.log('💲 Formatted Amount:', formatted);
        return formatted;
    }

    splitVenueAddress(address) {
        if (!address) return { line1: '', line2: '' };
        const parts = address.split(',');
        const venue = {
            line1: parts[0] || '',
            line2: parts.slice(1).join(',').trim() || ''
        };
        console.log('📍 Venue Address Split:', venue);
        return venue;
    }

    updateDisplayedEvents() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;

        this.displayedEvents = this.allEvents.slice(start, end);
        console.log(`📑 Displaying events for page ${this.currentPage}:`, this.displayedEvents);
    }

    handlePrevious() {
        console.log('⬅️ Previous button clicked');
        if (this.currentPage > 1) {
            this.currentPage--;
            console.log('📄 Current Page:', this.currentPage);
            this.updateDisplayedEvents();
        }
    }

    handleNext() {
        console.log('➡️ Next button clicked');
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            console.log('📄 Current Page:', this.currentPage);
            this.updateDisplayedEvents();
        }
    }

    handleViewDetails(event) {
        const recordId = event.target.dataset.id;
        console.log('🔍 View Details clicked for Record Id:', recordId);

        // Dispatch custom event to parent component
        const viewDetailsEvent = new CustomEvent('viewdetails', {
            detail: { recordId: recordId,
        type: 'UPCOMING' },
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(viewDetailsEvent);
    }

    get hasPrevious() {
        return this.currentPage <= 1;
    }

    get hasNext() {
        return this.currentPage >= this.totalPages;
    }

    get pageInfo() {
        const info = `Page ${this.currentPage} of ${this.totalPages}`;
        console.log('📘 Page Info:', info);
        return info;
    }

    get showingText() {
        const start = (this.currentPage - 1) * this.pageSize + 1;
        const end = Math.min(this.currentPage * this.pageSize, this.allEvents.length);
        const total = this.allEvents.length;
        const text = `Showing ${start}-${end} of ${total}`;
        console.log('📊 Showing Text:', text);
        return text;
    }

    get hasEvents() {
        const hasData = this.displayedEvents && this.displayedEvents.length > 0;
        console.log('📦 Has Events:', hasData);
        return hasData;
    }
}