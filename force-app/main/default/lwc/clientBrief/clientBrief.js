import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';



const FIELDS = [
     'Opportunity.Account.Name',
    'Opportunity.Event_Date__c',
    'Opportunity.Venue_Address__c',
    'Opportunity.Occasion__c',
    'Opportunity.Number_of_Guests__c',
    'Opportunity.Notes__c',
    'Opportunity.Contact__r.Name',
    'Opportunity.Contact__r.Email',
    'Opportunity.Contact__r.Phone',
    'Opportunity.Guest_arrival_time__c',
    'Opportunity.Guest_departure_time__c',
    'Opportunity.Staff_Start_Time__c',
    'Opportunity.Staff_Finish_Time__c',
    'Opportunity.Food_Drinks_Menu__c',
    'Opportunity.Number_of_Staff_Required__c',
    'Opportunity.Staffing_Details__c',
    'Opportunity.Uniform_Required__c'

];

export default class ClientBrief extends LightningElement {
    @api recordId;
    record;

wiredResult;

@wire(getRecord, { recordId: '$recordId', fields: FIELDS })
wiredRecord(result) {
    this.wiredResult = result;

    if (result.data) {
        this.record = result.data;
    } else if (result.error) {
        console.error(result.error);
    }
}

connectedCallback() {
    setTimeout(() => {
        if (this.wiredResult) {
            refreshApex(this.wiredResult);
        }
    }, 1000);
}

   get clientName() {
    return this.record?.fields?.Contact__r?.value?.fields?.Name?.value;
}

    get contactDetails() {
        const email = this.record?.fields?.Contact__r?.value?.fields?.Email?.value;
        const phone = this.record?.fields?.Contact__r?.value?.fields?.Phone?.value;

        if (email && phone) {
            return `${email} | ${phone}`;
        }
        return email || phone || '';
    }

    get businessName() {
    return this.record?.fields?.Account?.value?.fields?.Name?.value;
}

    
    get occasion() {
        return this.record?.fields?.Occasion__c?.value;
    }

  get eventDate() {
    const dateVal = this.record?.fields?.Event_Date__c?.value;
    if (!dateVal) return '';

    const date = new Date(dateVal);

    const dayName = date.toLocaleDateString('en-IN', { weekday: 'long' });
    const day = date.getDate();
    const month = date.toLocaleDateString('en-IN', { month: 'long' });
    const year = date.getFullYear();

    const suffix = this.getDaySuffix(day);

    return `${dayName} ${day}${suffix} ${month} ${year}`;
}

getDaySuffix(day) {
    if (day > 3 && day < 21) return 'th';
    switch (day % 10) {
        case 1: return 'st';
        case 2: return 'nd';
        case 3: return 'rd';
        default: return 'th';
    }
}

 get eventTime() {
    const arrival = this.record?.fields?.Guest_arrival_time__c?.value;
    const departure = this.record?.fields?.Guest_departure_time__c?.value;

    if (!arrival || !departure) return '';

    return `${this.formatDateTime(arrival)} – ${this.formatDateTime(departure)}`;
}

    get venue() {
        return this.record?.fields?.Venue_Address__c?.value;
    }


    get guests() {
        return this.record?.fields?.Number_of_Guests__c?.value;
    }

    get staffTiming() {
    const start = this.record?.fields?.Staff_Start_Time__c?.value;
    const end = this.record?.fields?.Staff_Finish_Time__c?.value;

    if (!start || !end) return '';

    return `${this.formatTimeOnly(start)} - ${this.formatTimeOnly(end)}`;
}
formatDateTime(dateTimeStr) {
    if (!dateTimeStr) return '';

    const date = new Date(dateTimeStr);

    return date.toLocaleTimeString('en-AU', {
        hour: '2-digit',
        minute: '2-digit',
        hour12: true,
        timeZone: 'Australia/Sydney' // ✅ IMPORTANT
    });
}
formatTimeOnly(timeStr) {
    if (!timeStr) return '';

    const [hoursStr, minutesStr] = timeStr.split(':');

    let hours = parseInt(hoursStr, 10);
    const minutes = minutesStr;

    const ampm = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12 || 12;

    return `${hours.toString().padStart(2, '0')}:${minutes} ${ampm}`;
}

get menu(){
    return this.record?.fields?.Food_Drinks_Menu__c?.value;
}

get staffing() {
    const count = this.record?.fields?.Number_of_Staff_Required__c?.value;
    const details = this.record?.fields?.Staffing_Details__c?.value;

    if (!count && !details) return '';

    let result = `Number of staff required: ${count || ''} Staff Member`;

    if (details) {
        result += ` (${details})`;
    }

    return result;
}

    get notes() {
        return this.record?.fields?.Notes__c?.value;
    }

    get uniform() {
        return this.record?.fields?.Uniform_Required__c?.value;
    }

    // Add remaining getters similarly
}