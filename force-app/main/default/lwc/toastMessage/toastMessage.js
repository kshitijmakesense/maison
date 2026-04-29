import { LightningElement, api } from 'lwc';

export default class ToastMessage extends LightningElement {
    @api toastTitle = '';
    @api toastMessage = '';
    @api toastVariant = 'success'; // success, error, warning, info
    
    showToast = false;
    autoCloseTimer;

    @api
    show(title, message, variant = 'success') {
        this.toastTitle = title;
        this.toastMessage = message;
        this.toastVariant = variant;
        this.showToast = true;

        // Auto close after 5 seconds for success, 10 seconds for error
        const duration = variant === 'error' ? 12000 : 5000;
        
        if (this.autoCloseTimer) {
            clearTimeout(this.autoCloseTimer);
        }

        this.autoCloseTimer = setTimeout(() => {
            this.closeToast();
        }, duration);
    }

    closeToast() {
        this.showToast = false;
        if (this.autoCloseTimer) {
            clearTimeout(this.autoCloseTimer);
        }
    }

    get toastClass() {
        return `toast-container ${this.toastVariant}`;
    }

    get iconName() {
        switch(this.toastVariant) {
            case 'success':
                return 'utility:success';
            case 'error':
                return 'utility:error';
            case 'warning':
                return 'utility:warning';
            case 'info':
                return 'utility:info';
            default:
                return 'utility:success';
        }
    }

    get toastIcon() {
        return this.showToast ? this.iconName : '';
    }
}