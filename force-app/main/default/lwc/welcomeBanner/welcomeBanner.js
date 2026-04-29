import { LightningElement, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import USER_NAME from '@salesforce/schema/User.Name';
import getAccountForUser from '@salesforce/apex/WelcomeBannerController.getAccountForUser';
import getDashboardData from '@salesforce/apex/WelcomeDashboardController.getDashboardData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class WelcomeBanner extends NavigationMixin(LightningElement) {
    @track userName;
    @track accountName;
    @track accountManager;
    @track dashboard = {};
    @track showForm = false;

    @wire(getRecord, { recordId: USER_ID, fields: [USER_NAME] })
    async userData({ data, error }) {
        if (data) {
            this.userName = getFieldValue(data, USER_NAME);
            await this.fetchAccountDetails();
            await this.fetchDashboardData();
        } else if (error) {
            console.error('Error fetching user data:', error);
        }
    }

    async fetchAccountDetails() {
        try {
            const acc = await getAccountForUser();
            if (acc) {
                this.accountName = acc.Name;
                this.accountManager =
                    acc.Account_Manager__r?.Name || 'Not Assigned';
            }
        } catch (error) {
            console.error('Error fetching account details:', error);
        }
    }

    async fetchDashboardData() {
        try {
            this.dashboard = await getDashboardData();
        } catch (error) {
            console.error('Error fetching dashboard data:', error);
        }
    }

    handleBookNewService() {
         this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Dynamic_Enquiry_Booking__c' // this must match your Experience Builder page name
            }
        });
    }

    closeForm() {
        this.showForm = false;
    }

    handleSuccess() {
        this.showForm = false;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Your service booking has been submitted!',
                variant: 'success'
            })
        );
        this.fetchDashboardData(); // refresh after booking
    }

    handleError() {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: 'Something went wrong while submitting the form.',
                variant: 'error'
            })
        );
    }
}