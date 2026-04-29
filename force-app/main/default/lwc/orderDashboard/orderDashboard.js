import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import getOrders from '@salesforce/apex/OrderDashboardController.getOrders';
import getServiceFilterOptions from '@salesforce/apex/OrderDashboardController.getServiceFilterOptions';
import getCurrentUserAccountId from '@salesforce/apex/CustomerPortalController.getCurrentUserAccountId';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import ORDER_OBJECT from '@salesforce/schema/Order';
import STATUS_FIELD from '@salesforce/schema/Order.Status';

export default class OrderDashboard extends NavigationMixin(LightningElement) {
    // filters
    @track status = '';
    @track startDate = null;
    @track endDate = null;
    @track searchText = '';
    @track selectedService = '';

    // options
    @track statusOptions = [];
    @track serviceOptions = [];

    @track showDateRange = false;

    accountId;

    // data & pagination
    allOrders = [];      // full data from Apex
    @track orders = [];  // current page
    page = 1;
    pageSize = 5;

    connectedCallback() {
        getCurrentUserAccountId().then(id => {
            this.accountId = id;
            this.loadOrders();
            this.loadServiceOptions();
        });
    }

    // dynamic Status options from Order.Status
    @wire(getObjectInfo, { objectApiName: ORDER_OBJECT })
    orderInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$orderInfo.data.defaultRecordTypeId',
        fieldApiName: STATUS_FIELD
    })
    statusPicklist({ data, error }) {
        if (data) {
            this.statusOptions = [{ label: 'All', value: '' }, ...data.values];
        } else if (error) {
            // eslint-disable-next-line no-console
            console.error('Status picklist error', error);
        }
    }

    get hasOrders() {
    return this.orders && this.orders.length > 0;
}

    // service dropdown – Item Name values from Order_Line_Item__c
    loadServiceOptions() {
        getServiceFilterOptions({ accountId: this.accountId })
            .then(result => {
                this.serviceOptions = [
                    { label: 'All', value: '' },
                    ...result.map(name => ({ label: name, value: name }))
                ];
            })
            .catch(err => {
                // eslint-disable-next-line no-console
                console.error('Service options error', err);
            });
    }

    // load orders from Apex
    loadOrders() {
        getOrders({
            accountId: this.accountId,
            status: this.status,
            startDate: this.startDate,
            endDate: this.endDate,
            searchText: this.searchText,
            service: this.selectedService
        })
            .then(result => {
                const mapped = result.map(ord => ({
                    ...ord,
                    // split comma-separated service list into array
                    serviceListArray: ord.serviceList
                        ? ord.serviceList.split(',').map(s => s.trim())
                        : [],
                    // status badge styling
                   statusBadgeClass:
    ord.status === 'Draft'
        ? 'status-badge draft'
    : ord.status === 'Completed'
        ? 'status-badge completed'
    : ord.status === 'Cancelled'
        ? 'status-badge cancelled'
    : 'status-badge other'
,
                    // only allow edit when Status = Draft
                    canEdit: ord.status === 'Draft'
                }));

                this.allOrders = mapped;
                this.page = 1;
                this.updatePage();
            })
            .catch(err => {
                // eslint-disable-next-line no-console
                console.error('getOrders error', err);
            });
    }

    // pagination helpers
    updatePage() {
        const start = (this.page - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.orders = this.allOrders.slice(start, end);
    }

    get totalPages() {
        return this.allOrders.length === 0
            ? 1
            : Math.ceil(this.allOrders.length / this.pageSize);
    }

    get isFirstPage() {
        return this.page === 1;
    }

    get isLastPage() {
        return this.page >= this.totalPages;
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

    // filter handlers
    clearFilters() {
        this.status = '';
        this.startDate = null;
        this.endDate = null;
        this.searchText = '';
        this.selectedService = '';
        this.showDateRange = false;
        this.loadOrders();
    }

    get dateRangeIcon() {
        return this.showDateRange ? '▲' : '▼';
    }
    toggleDateRange() {
        this.showDateRange = !this.showDateRange;
    }

    handleStatusChange(e) {
        this.status = e.detail.value;
        this.loadOrders();
    }
    handleStartDate(e) {
        this.startDate = e.detail.value;
        this.loadOrders();
    }
    handleEndDate(e) {
        this.endDate = e.detail.value;
        this.loadOrders();
    }
    handleSearch(e) {
        this.searchText = e.target.value;
        this.loadOrders();
    }
    handleServiceChange(e) {
        this.selectedService = e.detail.value;
        this.loadOrders();
    }

    // navigation
    viewDetails(event) {
        const id = event.currentTarget.dataset.id;
       window.location.href = `/edit-or-view-orders?recordId=${id}&mode=view`;
    }

    navigateToEdit(event) {
        const id = event.currentTarget.dataset.id;
       window.location.href = `/edit-or-view-orders?recordId=${id}&mode=edit`;
    }
}