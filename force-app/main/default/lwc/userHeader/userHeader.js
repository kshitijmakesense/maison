import { LightningElement,track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import communityId from '@salesforce/community/Id';
import userId from '@salesforce/user/Id';
import basePath from '@salesforce/community/basePath';
import isGuestUser from '@salesforce/user/isGuest';
import getProfilePicture from '@salesforce/apex/UserProfileController.getProfilePicture';
import getUserDetails from '@salesforce/apex/UserProfileController.getUserDetails';

 

export default class UserHeader extends NavigationMixin(LightningElement) {
    userId = userId;
    communityId = communityId;
    basePath = basePath;
    isGuestUser = isGuestUser;
    showUserMenu = false;
    userName = '';
    userProfileImage = '';
    userInitials = '';
    isLoading = true;
    accountId;
 
 

    @wire(getUserDetails)
    wiredUserDetails({ error, data }) {
        if (data) {
             console.log('get user details'); 
           console.log(data); 
         this.accountId = data.AccountId;
        console.log(this.accountId);
            this.userName = data.Name;
            if (data.Name) {
                const nameParts = data.Name.split(' ');
                if (nameParts.length > 1) {
                    this.userInitials = `${nameParts[0].charAt(0)}${nameParts[nameParts.length - 1].charAt(0)}`;
                } else {
                    this.userInitials = data.Name.substring(0, 2).toUpperCase();
                }
            }
            this.isLoading = false;
        } else if (error) {
            console.error('Error fetching user details', error);
            this.isLoading = false;
        }
    }
 
    @wire(getProfilePicture)
    wiredProfilePicture({ error, data }) {
        if (data) {
            this.userProfileImage = data;
        } else if (error) {
            console.error('Error fetching profile picture', error);
        }
    }
   
 
    toggleUserMenu() {
        this.showUserMenu = !this.showUserMenu;
    }
 
    closeUserMenu() {
        this.showUserMenu = false;
    }
 
    navigateToMyProfile() {
        // Get the base URL of the current site
        const siteUrl = window.location.origin;
       
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `${siteUrl}/profile/${this.userId}`
            }
        });
        this.closeUserMenu();
    }
   
    navigateToOffersAndPromotions() {
        const siteUrl = window.location.origin;
        if (this.accountId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    //url: `${siteUrl}/account/${this.accountId}/detail`
                    url: `${siteUrl}/vestar/offers-and-promotions`
                }
            });
        } else {
            console.warn('No AccountId found for the current user.');
        }
        this.closeUserMenu();
    }

  /*  navigateToAccountInformation() {
        const siteUrl = window.location.origin;
        if (this.accountId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: `${siteUrl}/account/${this.accountId}/detail`   
                }
            });
        } else {
            console.warn('No AccountId found for the current user.');
        }
        this.closeUserMenu();
    } */
    navigateToDistributor(recordId, recordName = null) {
        const siteUrl = window.location.origin;
        if (recordId) {
            // Build URL with optional recordName parameter
            let url = `${siteUrl}/vestar/distributor/${recordId}`;
            if (recordName) {
                // URL encode the record name to handle special characters and spaces
                url += `/${encodeURIComponent(recordName)}`;
            }
            
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: url
                }
            });
        } else {
            console.warn('No recordId provided for distributor navigation.');
        }
        this.closeUserMenu();
    }

    // Alternative method if you want to navigate to current user's distributor
    navigateToMyDistributor() {
        const siteUrl = window.location.origin;
        if (this.accountId) {
            // Assuming the accountId can be used as the distributor recordId
            // You might need to modify this based on your data model
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: `${siteUrl}/vestar/distributor/${this.accountId}`
                }
            });
        } else {
            console.warn('No AccountId found for the current user.');
        }
        this.closeUserMenu();
    }
 
    navigateToDashboard() {
        // Get the base URL of the current site
        const siteUrl = window.location.origin;
       
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `${siteUrl}/vestar/vedashboard`
            }
        });
        this.closeUserMenu();
    }




 navigateToAccountInformation() {
        // Get the base URL of the current site
        const siteUrl = window.location.origin;
       
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `${siteUrl}/account-information`
            }
        });
        this.closeUserMenu();
    }




    navigateToCreateUser() {
            this.closeUserMenu();

        // Get the base URL of the current site
        const siteUrl = window.location.origin;
       
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `${siteUrl}/create-new-user`
            }
        });
       
    }

    navigateToIncentive() {
        // Get the base URL of the current site
        const siteUrl = window.location.origin;
       
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `${siteUrl}/dealer-incentives`
            }
        });
        this.closeUserMenu();
    }

 
 
    navigateToSettings() {
        // Open settings page within the Experience site
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `${this.basePath}/settings`
            }
        });
        this.closeUserMenu();
    }
 
    navigateToLogin() {
        this[NavigationMixin.Navigate]({
            type: 'comm__loginPage',
            attributes: {
                actionName: 'login'
            }
        });
    }
 
    handleLogout() {
        
        // Construct the logout URL and redirect
        const logoutUrl = `${this.basePath}/secur/logout.jsp`;
        window.location.href = logoutUrl;
    }
}