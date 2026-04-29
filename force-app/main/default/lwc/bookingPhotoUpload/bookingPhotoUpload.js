import { LightningElement, api, track } from 'lwc';
import getPhotos from '@salesforce/apex/BookingPhotoService.getPhotos';
import deletePhoto from '@salesforce/apex/BookingPhotoService.deletePhoto';
import Toast from 'lightning/toast';
import getProfileName from '@salesforce/apex/BookingMenuService.getProfileName';
import updateFileAccess from '@salesforce/apex/BookingPhotoService.updateFileAccess';
import uploadPhotos from '@salesforce/apex/BookingPhotoService.uploadPhotos';

export default class BookingPhotoUpload extends LightningElement {

    @api recordId;
    @track photos = [];
    @track showModal = false;
    @track modalImage;
    @track profileName;
@track isInternalUser = false;
@track isUploading = false;
    connectedCallback() {
        this.loadPhotos();
          this.loadUserProfile();
    }

    loadUserProfile() {
    getProfileName()
        .then(result => {
            this.profileName = result;

            // 🔥 Adjust based on your org
            if (result !== 'Custom Customer Community User') {
                this.isInternalUser = true;
            }
        })
        .catch(error => {
            console.error(error);
        });
}

loadPhotos() {
    return getPhotos({ bookingId: this.recordId })   // 👈 return added
        .then(result => {

            this.photos = result.map(p => ({
                id: p.id,
                name: p.name,
                versionId: p.versionId,   // keep it
    url: this.getFileUrl(p.versionId)   // ✅ use versionId
            }));

            this.photos = [...this.photos];
        })
        .catch(error => {
            console.error(error);
        });
}
handleDeleteAll() {

    if (!confirm('Are you sure you want to delete all photos?')) {
        return;
    }

    const deletePromises = this.photos.map(p =>
        deletePhoto({ contentDocumentId: p.id })
    );

    Promise.all(deletePromises)
        .then(() => {

            Toast.show({
                label: 'Success',
                message: 'All photos deleted',
                variant: 'success'
            });

            this.photos = [];

        })
        .catch(error => {
            console.error(error);
        });
}
async handleDownloadAll() {

    for (let photo of this.photos) {

        const link = document.createElement('a');
       link.href = this.getFileUrl(photo.versionId); 
        link.download = photo.name || 'photo.jpg';

        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);

        // 🔥 delay prevents browser blocking
        await new Promise(resolve => setTimeout(resolve, 500));
    }
}


handleFileChange(event) {
    this.isUploading = true;

    const files = event.target.files;

    const promises = [];

    for (let file of files) {
        const reader = new FileReader();

        const p = new Promise(resolve => {
            reader.onload = () => {
                resolve({
                    fileName: file.name,
                    base64: reader.result.split(',')[1]
                });
            };
        });

        reader.readAsDataURL(file);
        promises.push(p);
    }

    Promise.all(promises)
        .then(data => {
            return uploadPhotos({
                bookingId: this.recordId,
                files: data
            });
        })
        .then(() => this.loadPhotos())
        .then(() => {
            Toast.show({
                label: 'Success',
                message: 'Photos uploaded',
                variant: 'success'
            });
        })
        .catch(error => {
            console.error(error);
        })
        .finally(() => {
    this.isUploading = false;

    const input = this.template.querySelector('input[type="file"]');
    if (input) {
        input.value = null;
    }
});
}

triggerFileInput() {
    const input = this.template.querySelector('input[type="file"]');
    if (input) {
        input.click();
    }
}
/*handleUploadFinished(event) {
    const uploadedFiles = event.detail.files;

    Toast.show({
        label: 'Success',
        message: `${uploadedFiles.length} file(s) uploaded`,
        variant: 'success'
    });

    // 🔥 wait for Salesforce to commit files
    setTimeout(() => {
        this.loadPhotos();
    }, 1000);
}*/

handleUploadFinished(event) {
    const uploadedFiles = event.detail.files;
    const docIds = uploadedFiles.map(f => f.documentId);

    // 🔥 WAIT before updating (IMPORTANT)
    setTimeout(() => {
        updateFileAccess({
            documentIds: docIds,
            recordId: this.recordId
        })
        .then(() => this.loadPhotos())
        .then(() => {
              Toast.show({
        label: 'Success',
        message: `${uploadedFiles.length} file(s) uploaded`,
        variant: 'success'
    });

        })
        .catch(error => console.error(error));
    }, 1500); // 🔥 increase delay
}

getFileUrl(versionId) {
    if (window.location.hostname.includes('site.com')) {
        const base = window.location.origin;
        const path = window.location.pathname.split('/')[1];
        return `${base}/${path}/sfc/servlet.shepherd/version/download/${versionId}`;
    }

    return `/sfc/servlet.shepherd/version/download/${versionId}`;
}

handlePreview(event) {
    const id = event.target.dataset.id;

    this.modalImage = this.getFileUrl(id);
    this.showModal = true;
}

@track showGallery = false;

openGallery() {
    this.showGallery = true;
}

closeGallery() {
    this.showGallery = false;
}
    closeModal() {
        this.showModal = false;
    }

handleDownload(event) {
    const id = event.target.dataset.id;

    window.open(this.getFileUrl(id), '_blank');
}

    handleRemove(event) {
        const id = event.target.dataset.id;

        deletePhoto({ contentDocumentId: id })
            .then(() => {
                Toast.show({
                    label: 'Deleted',
                    message: 'Photo removed',
                    variant: 'success'
                });

                this.loadPhotos();
            })
            .catch(error => {
                console.error(error);
            });
    }
}