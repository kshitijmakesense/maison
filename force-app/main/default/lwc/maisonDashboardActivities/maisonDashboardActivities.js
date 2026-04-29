import { LightningElement, wire } from 'lwc';
import getDashboardData from '@salesforce/apex/MaisonDashboardService.getDashboardData';

export default class MaisonDashboardActivities extends LightningElement {

    data;

    @wire(getDashboardData)
    wiredDashboard({ data }) {
        if (data) {
            this.data = data;
        }
    }

    get formattedOutstanding() {
        if (!this.data || !this.data.totalOutstanding) {
            return '0';
        }
        return Number(this.data.totalOutstanding).toLocaleString();
    }
}