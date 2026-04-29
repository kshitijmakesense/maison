import { LightningElement } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import globalToastStyles from '@salesforce/resourceUrl/globalToastStyles';

let toastContainer;
let stylesLoaded = false;

// Ensure styles + container are available
function ensureContainer() {
    if (!stylesLoaded) {
        loadStyle(null, globalToastStyles);
        stylesLoaded = true;
    }

    if (!toastContainer) {
        toastContainer = document.createElement('div');
        toastContainer.className = 'global-toast-container';
        document.body.appendChild(toastContainer);
    }
}

export function showToast(title, message, variant = 'info') {
    ensureContainer();

    const toast = document.createElement('div');
    toast.className = `global-toast ${variant}`;

    toast.innerHTML = `
        <div class="toast-header">${title}</div>
        <div class="toast-body">${message}</div>
        <button class="toast-close">×</button>
    `;

    toast.querySelector('.toast-close').addEventListener('click', () => {
        toast.classList.add('fade-out');
        setTimeout(() => toast.remove(), 300);
    });

    toastContainer.appendChild(toast);

    setTimeout(() => {
        if (toast.isConnected) {
            toast.classList.add('fade-out');
            setTimeout(() => toast.remove(), 300);
        }
    }, 4000);
}

export default class GlobalToast extends LightningElement {}