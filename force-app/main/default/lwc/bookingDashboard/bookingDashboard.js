import { LightningElement, track } from 'lwc';
import getBookings from '@salesforce/apex/BookingDashboardController.getBookings';
import getCurrentUserAccountId from '@salesforce/apex/CustomerPortalController.getCurrentUserAccountId';

export default class BookingDashboard extends LightningElement {
    @track enquiries = [];
    @track orders = [];
    @track activeTab = 'enquiries';

    @track searchKey = '';
    @track status = '';
    @track startDate = null;
    @track endDate = null;

    accountId;

    connectedCallback() {
        this.loadAccount();
    }

    loadAccount() {
        getCurrentUserAccountId()
            .then(accId => {
                this.accountId = accId;
                this.loadBookings();
            })
            .catch(err => console.error('Account fetch error:', err));
    }

    loadBookings() {
        getBookings({
            accountId: this.accountId,
            status: this.status,
            startDate: this.startDate,
            endDate: this.endDate
        })
            .then(result => {
                this.enquiries = this.formatRecords(result.enquiries);
                this.orders = this.formatRecords(result.orders);
            })
            .catch(error => {
                console.error('Error loading bookings:', error);
            });
    }

    formatRecords(list) {
        if (!list) return [];
        return list.map(r => ({
            id: r.Id,
            name: r.Name,
            date: r.Event_Date__c,
            guests: r.Number_of_Guests__c,
            venue: r.Venue_Address__c,
            budget: r.Estimated_Budget__c,
            status: r.StageName || r.Status
        }));
    }

    handleTabChange(event) {
        this.activeTab = event.target.dataset.tab;
    }

    handleStatusChange(event) {
        this.status = event.detail.value;
        this.loadBookings();
    }

    handleStartDate(event) {
        this.startDate = event.detail.value;
        this.loadBookings();
    }

    handleEndDate(event) {
        this.endDate = event.detail.value;
        this.loadBookings();
    }

    handleSearch(event) {
        this.searchKey = event.detail.value.toLowerCase();
    }

    get filteredEnquiries() {
        return this.filterList(this.enquiries);
    }

    get filteredOrders() {
        return this.filterList(this.orders);
    }

    filterList(list) {
        if (!this.searchKey) return list;

        return list.filter(
            item =>
                (item.name && item.name.toLowerCase().includes(this.searchKey)) ||
                (item.venue && item.venue.toLowerCase().includes(this.searchKey))
        );
    }
}