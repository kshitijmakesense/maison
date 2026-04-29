import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getEnquiries from '@salesforce/apex/EnquiryDashboardController.getEnquiries';
import getServiceFilterOptions from '@salesforce/apex/EnquiryDashboardController.getServiceFilterOptions';
import getCurrentUserAccountId from '@salesforce/apex/CustomerPortalController.getCurrentUserAccountId';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import STAGE_NAME_FIELD from '@salesforce/schema/Opportunity.StageName';

export default class EnquiryDashboard extends NavigationMixin(LightningElement) {
   
    @track status = '';
    @track startDate = null;
    @track endDate = null;
    @track searchText = '';
    @track selectedService = '';

    @track statusOptions = [];
    @track serviceOptions = [];

    @track showDateRange = false; // For expanding/collapsing date range section

    accountId;

    allEnquiries = [];   // full data from Apex
@track enquiries = [];      // paginated data shown in UI
page = 1;
pageSize = 5;



    connectedCallback() {
        getCurrentUserAccountId().then(id => {
            this.accountId = id;
            this.loadEnquiries();
            this.loadServiceOptions();
        });
    }

    // ⚡ Fetch StageName picklist dynamically
    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    opportunityInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$opportunityInfo.data.defaultRecordTypeId',
        fieldApiName: STAGE_NAME_FIELD
    })
    stagePicklistValues({ data, error }) {
        if (data) {
            this.statusOptions = [{ label: 'All', value: '' }, ...data.values];
        }
        if (error) {
            console.error('Picklist error:', error);
        }
    }

    // ⚡ Load service dropdown
    loadServiceOptions() {
        getServiceFilterOptions({ accountId: this.accountId })
            .then(result => {
                this.serviceOptions = [
                    { label: 'All', value: '' },
                    ...result.map(name => ({ label: name, value: name }))
                ];
            });
    }

    // ⚡ Load enquiries
loadEnquiries() {
    console.log('🔵 Loading enquiries...');

    const recordTypeLabels = {
    Sydney_Bookings: 'Sydney Booking',
    Melbourne_Bookings: 'Melbourne Booking',
    Catering: 'Catering',
    Coffee_Cart: 'Coffee Cart'
};


    getEnquiries({
        accountId: this.accountId,
        status: this.status,
        startDate: this.startDate,
        endDate: this.endDate,
        searchText: this.searchText,
        service: this.selectedService
    })
   .then(result => {

    const mapped = result.map(enq => ({
        ...enq,
        recordTypeLabel: enq.recordTypeLabel,
        serviceListArray: enq.serviceList
            ? enq.serviceList.split(',').map(s => s.trim())
            : [],
        arrivalTime: enq.arrivalTimeFormatted,
        departureTime: enq.departureTimeFormatted,
        statusBadgeClass:
            enq.stage === 'Closed Lost'
                ? 'status-badge lost'
                : 'status-badge open',
        canEdit:
            enq.stage !== 'Quote Accepted' &&
            enq.stage !== 'Closed' &&
            enq.stage !== 'Closed Won' &&
            enq.stage !== 'Closed Lost'
    }));

    this.allEnquiries = mapped;
   this.page = 1;       // reset to first page on every filter/search change
        this.updatePage();

   
})

    .catch(err => {
        console.error('❌ Error from Apex:', err);
    });
}

updatePage() {
    const start = (this.page - 1) * this.pageSize;
    const end = start + this.pageSize;
    this.enquiries = this.allEnquiries.slice(start, end);
}

get totalPages() {
    return this.allEnquiries.length === 0
        ? 1
        : Math.ceil(this.allEnquiries.length / this.pageSize);
}

get isFirstPage() {
    return this.page === 1;
}

get isLastPage() {
    return this.page >= this.totalPages;
}

   get hasEnquiries() {
    return this.enquiries && this.enquiries.length > 0;
}

handlePrev() {
    if (this.page > 1) {
        this.page -= 1;
        this.updatePage();
    }
}

handleNext() {
    if (this.page < this.totalPages) {
        this.page += 1;
        this.updatePage();
    }
}


clearFilters() {
    this.status = '';
    this.startDate = null;
    this.endDate = null;
    this.searchText = '';
    this.selectedService = '';
    this.showDateRange = false; // optional: collapse it

    this.loadEnquiries();
}


    // ▾ Date Range Toggle
    get dateRangeIcon() {
        return this.showDateRange ? '▲' : '▼';
    }
    toggleDateRange() {
        this.showDateRange = !this.showDateRange;
    }

    // Filters
    handleStatusChange(e) {
        this.status = e.detail.value;
        this.loadEnquiries();
    }
    handleStartDate(e) {
        this.startDate = e.detail.value;
        this.loadEnquiries();
    }
    handleEndDate(e) {
        this.endDate = e.detail.value;
        this.loadEnquiries();
    }
    handleSearch(e) {
        this.searchText = e.target.value;
        this.loadEnquiries();
    }
    handleServiceChange(e) {
        this.selectedService = e.detail.value;
        this.loadEnquiries();
    }

    // View Details
    viewDetails(event) {
        const id = event.currentTarget.dataset.id;
        /*this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: id,
                objectApiName: 'Opportunity',
                actionName: 'view'
            }
        });*/
       window.location.href = `/edit-enquiry?recordId=${id}&mode=view&source=service`;

    }

    navigateToEdit(event) {
    const id = event.currentTarget.dataset.id;
    //window.location.href = `/edit-enquiry?recordId=${id}`;
    window.location.href = `/edit-enquiry?recordId=${id}&mode=edit`;
}


}