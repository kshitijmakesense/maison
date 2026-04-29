import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generatePDFAndAttach from '@salesforce/apex/OrderShareController.generatePDFAndAttach';
 
export default class OrderPdf extends LightningElement {
    @api recordId; // This is the Order Id
    @track isLoading = false;
    @track message = '';
    @track error = '';
 
    get vfPageUrl() {
        // This builds the URL to the Visualforce page, passing the recordId as a parameter
        return `/apex/OrderPDFPage?id=${this.recordId}`;
    }
 
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
 
    handleSave() {
        console.log('Record ID:', this.recordId); // Debug line
        
        if (!this.recordId) {
            this.showToast('Error', 'No Order ID available', 'error');
            return;
        }
        
        this.isLoading = true;
        this.message = '';
        this.error = '';
       
        generatePDFAndAttach({ orderId: this.recordId })  // Changed from quoteId to orderId
            .then(() => {
                this.message = 'Order PDF saved successfully.';
                this.showToast('Success', 'Order PDF saved successfully.', 'success');
                setTimeout(() => {
                    this.dispatchEvent(new CloseActionScreenEvent());
                }, 1500); // Small delay to show success message
            })
            .catch(error => {
                console.error('Error saving PDF:', error);
                const errorMessage = error.body?.message || error.message || 'An unknown error occurred';
                this.error = `Failed to save PDF: ${errorMessage}`;
                this.showToast('Error', `Failed to save PDF: ${errorMessage}`, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
 
    handleDownload() {
        // Direct download of PDF
        const downloadUrl = `/apex/OrderPDFPage?id=${this.recordId}`;
        window.open(downloadUrl, '_blank');
    }
 
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}