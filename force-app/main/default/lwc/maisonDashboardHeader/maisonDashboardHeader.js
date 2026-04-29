import { LightningElement, wire } from 'lwc';
import getCurrentUser from '@salesforce/apex/MaisonPortalUserController.getCurrentUser';

export default class MaisonDashboardHeader extends LightningElement {

    user;

    @wire(getCurrentUser)
    wiredUser({ data, error }) {
        if (data) {
            this.user = data;
        } else if (error) {
            console.error('Error fetching user', error);
        }
    }

    get userName() {
        return this.user ? this.user.Name : '';
    }

    get userEmail() {
        return this.user ? this.user.Email : '';
    }

    get userPhoto() {
        return this.user ? this.user.SmallPhotoUrl : '';
    }
}