import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import isGuest from '@salesforce/user/isGuest';
import USER_ID from '@salesforce/user/Id';
import USER_TITLE_FIELD from '@salesforce/schema/User.Title';

export default class NavigationBar extends NavigationMixin(LightningElement) {
    @track isGuestUser = isGuest;
    @track userTitle = '';

    // Wire method to get current user's title
    @wire(getRecord, { 
        recordId: USER_ID, 
        fields: [USER_TITLE_FIELD] 
    })
    wiredUser({ error, data }) {
        if (data) {
            this.userTitle = data.fields.Title.value || '';
        } else if (error) {
            console.error('Error fetching user data:', error);
            this.userTitle = '';
        }
    }

    // Navigation items configuration with role-based visibility
get navigationItems() {
    const items = [
        { label: 'Home', name: 'home', url: '/', visible: true, icon: '🏠' },
        { label: 'Quick Service Booking', name: 'quick service booking', url: '/quick-service-booking', visible: !this.isGuestUser, icon: '➕' },
        { label: 'Service Requests', name: 'service requests', url: '/service-requests', visible: !this.isGuestUser, icon: '📄' },
        { label: 'Service Bookings', name: 'service bookings', url: '/service-bookings', visible: !this.isGuestUser, icon: '📅' },

        // ⭐ NEW NAV ITEM — Proposals & Quotes
        { label: 'Proposals & Quotes', name: 'proposals quotes', url: '/proposals-and-quotes', visible: !this.isGuestUser, icon: '📑' },
    // ⭐ NEW NAV ITEM — Invoices
        { label: 'Invoices', name: 'invoices', url: '/invoices', visible: !this.isGuestUser, icon: '💰' }
];

    return items
        .filter(i => i.visible)
        .map(i => ({
            ...i,
            isActive: this.currentPage === i.url
        }));
}




    get userTypeClass() {
        return this.isGuestUser ? 'guest-user' : 'logged-in-user';
    }

    get userStatus() {
        if (this.isGuestUser) {
            return 'Guest User';
        }
        return this.userTitle ? `${this.userTitle} - Logged In` : 'Logged In';
    }

    // Helper method to check if user has specific role
    hasRole(role) {
        return this.userTitle === role;
    }

    // Helper method to check if user has any of the specified roles
    hasAnyRole(roles) {
        return roles.includes(this.userTitle);
    }

    handleNavigation(event) {
        event.preventDefault();
        const selectedItem = event.currentTarget.dataset.name;
        const url = event.currentTarget.dataset.url;

        // Custom navigation logic
        this.navigateToPage(selectedItem, url);
    }

    navigateToPage(pageName, url) {
        // Use NavigationMixin for proper navigation in community
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
    }

   get currentPage() {
    let path = window.location.pathname.toLowerCase();

    // Remove Experience Cloud prefix
    if (path.startsWith('/s/')) {
        path = path.replace('/s', '');
    }
    if (path === '/s') {
        path = '/';
    }

    return path;
}


}