import { LightningElement, api, track } from 'lwc';
import getMenuFiles from '@salesforce/apex/BookingMenuService.getMenuFiles';
import deleteExistingMenu from '@salesforce/apex/BookingMenuService.deleteExistingMenu';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import uploadMenuFile from '@salesforce/apex/BookingMenuService.uploadMenuFile';
import Toast from 'lightning/toast';
import { NavigationMixin } from 'lightning/navigation';
import getFileDownloadUrl from '@salesforce/apex/BookingMenuService.getFileDownloadUrl';
import getProfileName from '@salesforce/apex/BookingMenuService.getProfileName';

export default class BookingMenuUpload extends NavigationMixin(LightningElement) { 

    @api recordId;

    @track fileName;
    @track fileId;
    @track isLoading = false;

     @track profileName;
    @track isInternalUser = false;

  

    connectedCallback() {
         this.loadMenu();
         this.loadUserProfile();
    }

    loadUserProfile() {
        getProfileName()
            .then(result => {
                this.profileName = result;
                 // 🔥 Adjust based on your org profile names
                if (result != 'Custom Customer Community User') {
                    this.isInternalUser = true;
                }
            })
            .catch(error => {
                console.error(error);
            });
    }

    get containerClass() {
    return this.isInternalUser
        ? 'menu-container internal-center'
        : 'menu-container';
}

showToast(title, message, variant) {
    Toast.show({
        label: title,
        message: message,
        variant: variant
    });
}
loadMenu() {
    getMenuFiles({ bookingId: this.recordId })
        .then(result => {
            if (result.length > 0) {
                this.fileId = result[0].id;      // ✅ FIXED
                this.fileName = result[0].name;  // ✅ FIXED
            } else {
                this.fileId = null;
                this.fileName = null;
            }
        })
        .catch(error => {
            console.error(error);
        });
}

handleDownload() {
    const id = this.fileId;

    let url;

    // 🔥 Detect if running in Experience Cloud
    if (window.location.hostname.includes('site.com')) {

        const base = window.location.origin;
        const path = window.location.pathname.split('/')[1];
        const fullBase = `${base}/${path}`;

        url = `${fullBase}/sfc/servlet.shepherd/document/download/${id}`;

    } else {
        // 🔥 Internal Salesforce (Lightning)
        url = `/sfc/servlet.shepherd/document/download/${id}`;
    }

    window.open(url, '_blank');
}



    handleFileChange(event) {
        const input = event.target; 
        const file = input.files[0];

        if (!file) return;
        if (file.size > 5000000) {
            this.showToast('Error', 'File size exceeds 5MB', 'error');
            return;
        }
        const reader = new FileReader();

        reader.onload = () => {
            const base64 = reader.result.split(',')[1];

            uploadMenuFile({
                bookingId: this.recordId,
                fileName: file.name,
                base64Data: base64
            })
           .then(result => {
                this.fileId = result;
                this.fileName = file.name;

                this.showToast('Success', 'Menu uploaded successfully', 'success');

                input.value = null; // ✅ FIXED
            })
            .catch(error => {
                console.error(error);
                this.showToast('Error', 'Upload failed', 'error');
            });
        };

        reader.readAsDataURL(file);
       
    }

    
    triggerFileInput() {
        this.template.querySelector('input[type="file"]').click();
    }

    get hasMenu() {
        return this.fileId != null;
    }


handleReplace() {

    if (!confirm('Are you sure you want to replace the existing menu?')) {
        return;
    }

    deleteExistingMenu({ bookingId: this.recordId })
        .then(() => {
            this.fileId = null;
            this.fileName = null;

            this.showToast('Success', 'Old menu removed. Upload new one.', 'success');
        })
        .catch(error => {
            console.error(error);
        });
}
   
}