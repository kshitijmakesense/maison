import { LightningElement, api, track } from 'lwc';
import getPreferredStaff from '@salesforce/apex/PreferredStaffFavorites.getPreferredStaff';

export default class PreferredStaffFavorites extends LightningElement {

 
    @track staffList = [];

    _recordId;

@api
set recordId(value) {
    this._recordId = value;

    if (value) {
        console.log('recordId received:', value); // ✅ debug
        this.loadData();
    }
}

get hasStaff() {
    return this.staffList && this.staffList.length > 0;
}

get recordId() {
    return this._recordId;
}

    loadData() {
        getPreferredStaff({ contactId: this.recordId })
            .then(result => {
                this.staffList = result;
                console.log('Favorites:', result);
            })
            .catch(error => {
                console.error('error: ',error);
            });
    }

    handleImageError(event) {
        event.target.src = '/img/default_avatar.png';
    }
}