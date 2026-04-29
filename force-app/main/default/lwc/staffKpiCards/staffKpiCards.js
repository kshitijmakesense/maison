import { LightningElement, api, wire } from 'lwc';
import getStaffKpi from '@salesforce/apex/StaffKpiController.getStaffKpi';

export default class StaffKpiCards extends LightningElement {
    @api recordId;
    data;
    error;
    staffPhotoUrl;

    @wire(getStaffKpi, { staffId: '$recordId' })
    wiredKpis({ data, error }) {
        if (data) {
            this.data = data;
            this.error = undefined;
            
            // Set staff photo URL if available
            if (data.photoUrl) {
                this.staffPhotoUrl = data.photoUrl;
            }
        } else if (error) {
            this.error = error;
            this.data = undefined;
            console.error('Error loading staff KPIs:', error);
        }
    }
}