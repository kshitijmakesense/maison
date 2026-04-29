import { LightningElement, track } from 'lwc';
import getRecentActivities from '@salesforce/apex/RecentActivityController.getRecentActivities';
import getCurrentUserAccountId from '@salesforce/apex/CustomerPortalController.getCurrentUserAccountId';
import { NavigationMixin } from 'lightning/navigation';

export default class RecentActivityTimeline extends NavigationMixin(LightningElement) {
    @track accountId;
    @track activities = [];
    @track error;

    connectedCallback() {
        this.loadActivities();
    }

    loadActivities() {
        getCurrentUserAccountId()
            .then(result => {
                this.accountId = result;
                if (this.accountId) {
                   return getRecentActivities({ accountId: this.accountId });
                   
                } else {
                    throw new Error('No Account linked to this user');
                }
            })
            .then(result => {
                
    console.log("=== RAW ACTIVITIES FROM APEX ===");
    console.log(JSON.parse(JSON.stringify(result)));

    // Log how many and what types
    console.log("Total activities returned:", result.length);

    const types = result.map(r => r.Type);
    console.log("Activity types in order:", types);

    // Check if invoice exists
    const invoiceRecords = result.filter(r => r.Type === 'Invoice');
    console.log("Invoice records found:", invoiceRecords);

    // If invoice exists, print their dates
    if (invoiceRecords.length > 0) {
        invoiceRecords.forEach(rec => {
            console.log(`Invoice: ${rec.Name} | SystemModstamp: ${rec.ActivityDate}`);
        });
    } else {
        console.warn("⚠ NO INVOICE RECORDS IN APEX RESULT");
    }
                this.activities = result.map(act => {
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

                    let timeAgo = this.getTimeAgo(act.ActivityDate);
return {
    ...act,
    ActivityDateOrg: act.ActivityDate,
    ActivityDate: formattedDate,
    FormattedAmount: formattedAmount,
    TimeAgo: timeAgo,
    statusColor: this.getStatusColor(act.Type, act.Status),
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
            })
            .catch(error => {
                console.error('Error loading activities:', error);
                this.error = error;
            });
    }

    // ⬇️ NEW: Only show first 3 activities
    get activitiesToShow() {
        return this.activities ? this.activities.slice(0, 3) : [];
    }

    // ⬇️ NEW: When user clicks "View All"
    /*handleViewAll() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Opportunity', // change if needed
                actionName: 'list'
            },
            state: {
                filterName: 'Recent' // or any other list view
            }
        });
    }*/

        handleViewAll() {
    this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: {
            url: '/all-recent-activity'
        }
    });
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

    getStatusColor(type, status) {
        status = status ? status.toLowerCase() : '';
        type = type ? type.toLowerCase() : '';

        if (type === 'enquiry') {
            if (status === 'open') return 'orange';
            if (status === 'closed') return 'green';
        }
        if (type === 'event bookings') {
            if (status === 'confirmed') return 'green';
            if (status === 'draft') return 'orange';
            if (status === 'cancelled') return 'red';
        }
        if (type === 'quote') {
            if (status === 'accepted') return 'green';
            if (status === 'rejected') return 'red';
            return 'orange';
        }
        if (type === 'invoice') {
            if (status === 'paid') return 'green';
            if (status === 'unpaid') return 'orange';
            if (status === 'overdue') return 'red';
        }
        if (type === 'payment') {
            if (status === 'completed') return 'green';
            if (status === 'pending') return 'orange';
        }
        return 'gray';
    }

    getIconForType(type) {
        type = type ? type.toLowerCase() : '';

        switch (type) {
            case 'enquiry':
                return { iconName: 'standard:lead', iconColor: '#0ea5e9' };
            case 'event bookings':
                return { iconName: 'standard:event', iconColor: '#22c55e' };
            case 'quote':
                return { iconName: 'standard:feedback', iconColor: '#f59e0b' };
            case 'invoice':
                return { iconName: 'standard:currency', iconColor: '#9333ea' };
            case 'payment':
                return { iconName: 'standard:payment', iconColor: '#2563eb' };
            default:
                return { iconName: 'utility:note', iconColor: '#94a3b8' };
        }
    }

    handleNavigate(event) {
    const recordId = event.currentTarget.dataset.id;
    const type = event.currentTarget.dataset.type?.toLowerCase();

    // 1️⃣ Special handling for enquiry
    if (type === 'enquiry') {
        // Navigate to your custom LWC route
        window.location.href = `/edit-enquiry?recordId=${recordId}&mode=view&source=recent`;
        return;
    } else if (type == 'event bookings') {
        window.location.href = `/edit-or-view-orders?recordId=${recordId}&mode=view&source=recent`;
    } else if (type == 'quote') {
                 window.location.href = `/quotedetailspage?id=${recordId}&source=recent`;
            } else if(type == 'invoice') {
                window.location.href = `/invoice-details?id=${recordId}&source=recent`;
            }


}


}