import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getRecentActivities from '@salesforce/apex/RecentActivityController.getRecentActivities';
import getCurrentUserAccountId from '@salesforce/apex/CustomerPortalController.getCurrentUserAccountId';

export default class RecentActivityListPage extends NavigationMixin(LightningElement) {

    @track allActivities = [];
    @track filteredActivities = [];

    @track paginatedActivities = [];
    @track pageNumber = 1;
    pageSize = 10;

    filterType = '';
    filterStatus = '';
    fromDate = '';
    toDate = '';

    typeOptions = [
        { label: 'All', value: '' },
        { label: 'Enquiry', value: 'enquiry' },
        { label: 'Event Booking', value: 'event bookings' },
        { label: 'Quote', value: 'quote' },
        { label: 'Invoice', value: 'invoice' }
    ];

    statusOptions = [
        { label: 'All', value: '' },
        { label: 'Open', value: 'open' },
        { label: 'Confirmed', value: 'confirmed' },
        { label: 'Draft', value: 'draft' },
        { label: 'Cancelled', value: 'cancelled' },
        { label: 'Paid', value: 'paid' },
        { label: 'Unpaid', value: 'unpaid' }
    ];

    connectedCallback() {
        this.loadData();
    }

    loadData() {
        getCurrentUserAccountId()
            .then(accId => getRecentActivities({ accountId: accId }))
            .then(result => {
                //this.allActivities = result;
                this.allActivities = result.map(act => {
    let formattedDate = '';
    if (act.ActivityDate) {
        const dt = new Date(act.ActivityDate);
        formattedDate = dt.toLocaleDateString('en-US', {
            month: 'short',
            day: 'numeric',
            year: 'numeric'
        });
    }

    let formattedAmount = '';
    if (act.Amount) {
        formattedAmount = new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 0
        }).format(act.Amount);
    }

    return {
        ...act,
        ActivityDateOrg: act.ActivityDate,
        ActivityDate: formattedDate,
        FormattedAmount: formattedAmount,
        TimeAgo: this.getTimeAgo(act.ActivityDate),
         iconData: this.getIconForType(act.Type),
    iconStyle: `
        background:${this.getIconForType(act.Type).iconColor};
        border-radius:50%;
        width:24px;
        height:24px;
        display:flex;
        align-items:center;
        justify-content:center;
    `
    };
});

                this.filteredActivities = [...this.allActivities];
                this.updatePagination();
            });
            console.log('Activities loaded: ', this.allActivities.length);
console.log('Filtered activities: ', this.filteredActivities.length);
console.log('Paginated activities: ', this.paginatedActivities.length);

    }

    // FILTER HANDLERS
    handleTypeChange(e) {
        this.filterType = e.detail.value;
        this.applyFilters();
    }
    handleStatusChange(e) {
        this.filterStatus = e.detail.value;
        this.applyFilters();
    }
    handleFromDate(e) {
        this.fromDate = e.detail.value;
        this.applyFilters();
    }
    handleToDate(e) {
        this.toDate = e.detail.value;
        this.applyFilters();
    }

   applyFilters() {
    this.filteredActivities = this.allActivities.filter(a => {

        const typeMatch = this.filterType ? a.Type.toLowerCase() === this.filterType : true;
        const statusMatch = this.filterStatus ? a.Status.toLowerCase() === this.filterStatus : true;

        const dateObj = new Date(a.ActivityDateOrg || a.ActivityDate);
        if (isNaN(dateObj)) return false;

        const fromOk = this.fromDate ? dateObj >= new Date(this.fromDate) : true;
        const toOk = this.toDate ? dateObj <= new Date(this.toDate) : true;

        return typeMatch && statusMatch && fromOk && toOk;
    });

    this.pageNumber = 1;
    this.updatePagination();
}

get hasActivities() {
    return this.paginatedActivities && this.paginatedActivities.length > 0;
}

getTimeAgo(dateStr) {
    if (!dateStr) return '';
    const date = new Date(dateStr.endsWith('Z') ? dateStr : dateStr + 'Z');
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
    const diffDays = Math.floor(diffHours / 24);
    if (diffHours < 1) return 'Just now';
    if (diffHours < 24) return `${diffHours} hour${diffHours === 1 ? '' : 's'} ago`;
    return `${diffDays} day${diffDays === 1 ? '' : 's'} ago`;
}

getIconForType(type) {
    type = type?.toLowerCase();
    switch (type) {
        case 'enquiry': return { iconName: 'standard:lead', iconColor: '#0ea5e9' };
        case 'event bookings': return { iconName: 'standard:event', iconColor: '#22c55e' };
        case 'quote': return { iconName: 'standard:feedback', iconColor: '#f59e0b' };
        case 'invoice': return { iconName: 'standard:currency', iconColor: '#9333ea' };
        default: return { iconName: 'utility:note', iconColor: '#94a3b8' };
    }
}

    // PAGINATION
    updatePagination() {
        const start = (this.pageNumber - 1) * this.pageSize;
        const end = start + this.pageSize;

        this.paginatedActivities = this.filteredActivities.slice(start, end);
    }

    nextPage() {
        if (this.pageNumber < this.totalPages) {
            this.pageNumber++;
            this.updatePagination();
        }
    }

    prevPage() {
        if (this.pageNumber > 1) {
            this.pageNumber--;
            this.updatePagination();
        }
    }

    get totalPages() {
        return Math.ceil(this.filteredActivities.length / this.pageSize);
    }

    get isPrevDisabled() {
        return this.pageNumber === 1;
    }
    get isNextDisabled() {
        return this.pageNumber >= this.totalPages;
    }

    // NAVIGATION
    handleNavigate(event) {
    const recordId = event.currentTarget.dataset.id;
    const type = event.currentTarget.dataset.type?.toLowerCase();

    // 1️⃣ Special handling for enquiry
    if (type === 'enquiry') {
        // Navigate to your custom LWC route
        window.location.href = `/edit-enquiry?recordId=${recordId}&mode=view&source=recentList`;
        return;
    } else if (type == 'event bookings') {
        window.location.href = `/edit-or-view-orders?recordId=${recordId}&mode=view&source=recentList`;
    } else if (type == 'quote') {
            window.location.href = `/quotedetailspage?id=${recordId}&source=recentList`;
    }else if(type == 'invoice') {
                window.location.href = `/invoice-details?id=${recordId}&source=recentList`;
            }

   
}


}