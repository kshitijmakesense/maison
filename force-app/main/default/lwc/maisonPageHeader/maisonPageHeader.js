import { LightningElement, api, wire } from 'lwc';
import getCurrentUser from '@salesforce/apex/MaisonPortalUserController.getCurrentUser';
import MAISON_LOGO from '@salesforce/resourceUrl/MaisonLogo';

export default class MaisonPageHeader extends LightningElement {

    @api activePage; // 👈 receives page from shell

    user;
     logoUrl = MAISON_LOGO;

    @wire(getCurrentUser)
    wiredUser({ data }) {
        if (data) this.user = data;
    }

    showMenu = false;

toggleMenu() {
    this.showMenu = !this.showMenu;
}

handleLogout() {
     // Construct the logout URL and redirect
        const logoutUrl = `${this.basePath}/secur/logout.jsp`;
        window.location.href = logoutUrl;
}


    /* ---------- PAGE CONFIG ---------- */
    get pageConfig() {
        return {
            dashboard: {
                title: `Welcome, ${this.user?.Name || ''}`,
                subtitle: `Here's an overview of your account and recent activities`
            },
            quotes: {
                title: 'Your Quotes',
                subtitle: 'View and manage all your event quotes'
            },
            bookings: {
                title: 'Your Bookings',
                subtitle: 'View all your confirmed and past bookings'
            },
            invoices: {
                title: 'Your Invoices',
                subtitle: 'Manage all your invoices and payment history'
            },
            payments: {
                title: 'Payment Management',
                subtitle: 'View outstanding balances and make payments'
            }
        };
    }
get title() {
    if (!this.activePage) return '';
    return this.pageConfig[this.activePage]?.title || '';
}

get subtitle() {
    if (!this.activePage) return '';
    return this.pageConfig[this.activePage]?.subtitle || '';
}

    get userEmail() {
        return this.user?.Email || '';
    }

    get userPhoto() {
        return this.user?.SmallPhotoUrl || '';
    }

    get userName(){
        return this.user?.Name || '';
    }

}