import { LightningElement, track, wire } from 'lwc';
import getPastEvents from '@salesforce/apex/MaisonPastEventsController.getPastEvents';
import { NavigationMixin } from 'lightning/navigation';
import createEnquiry from '@salesforce/apex/MaisonReorderController.createEnquiry';
import getStaffByBooking from '@salesforce/apex/MaisonStaffRatingController.getStaffByBooking';
import saveRatings from '@salesforce/apex/MaisonStaffRatingController.saveRatings';
import getFeedback from '@salesforce/apex/MaisonFeedbackController.getFeedback';
import saveFeedback from '@salesforce/apex/MaisonFeedbackController.saveFeedback';
import Toast from 'lightning/toast';
import getDynamicForm from '@salesforce/apex/MaisonReorderController.getDynamicForm';


export default class MaisonPastEvents extends NavigationMixin(LightningElement) {
    @track events = [];
    @track pageNumber = 1;
    @track pageSize = 5;
    @track totalRecords = 0;
    @track totalPages = 0;
    @track isLoading = false;
    @track error;
   @track dynamicFields = [];
@track recordType;
activeSections = ['Enquiry Details'];

@track sections = [];

    @track showReorderModal = false;
@track selectedBookingId;

@track occasion;
@track guests;
@track venue;
@track eventDate;
@track arrivalDateTime;
@track departureDateTime;

@track showRatingModal = false;
@track staffList = [];

@track showFeedbackModal = false;



@track feedback = {
    service: 0,
    food: 0,
    experience: 0,
    comments: '',
    serviceStars: [],
    foodStars: [],
    experienceStars: []
};

handleSectionToggle(event) {
    const openSections = event.detail.openSections;

    // 🔥 Always keep Enquiry Details open
    if (!openSections.includes('Enquiry Details')) {
        this.activeSections = ['Enquiry Details'];
    } else {
        this.activeSections = openSections;
    }
}

groupFields(fields) {

    const groups = {
        'Event Details': [],
        'Service & Requirements': []
    };

    fields.forEach(f => {

        const key = (f.apiName || '').toLowerCase();

        // 🔥 CLONE OBJECT (IMPORTANT FIX)
        const fieldClone = { ...f };

        if (
            key.includes('date') ||
            key.includes('event') ||
            key.includes('occasion') ||
            key.includes('guest') ||
            key.includes('staff') ||
            key.includes('venue')
        ) {
            groups['Event Details'].push(fieldClone);
        } else {
            groups['Service & Requirements'].push(fieldClone);
        }
    });

    return [
        {
            label: 'Event Details',
            fields: groups['Event Details']
        },
        {
            label: 'Service & Requirements',
            fields: groups['Service & Requirements']
        }
    ];
}
toggleMenu(event) {
     event.stopPropagation();  
    const recordId = event.currentTarget.dataset.id;

    this.events = this.events.map(e => {
        return {
            ...e,
            showMenu: e.Id === recordId ? !e.showMenu : false
        };
    });
}
stopPropagation(event) {
    event.stopPropagation();
}
get ratingOptions() {
    return [
        { label: '1', value: '1' },
        { label: '2', value: '2' },
        { label: '3', value: '3' },
        { label: '4', value: '4' },
        { label: '5', value: '5' }
    ];
}

handleReorder(event) {
    this.selectedBookingId = event.currentTarget.dataset.id;
    this.isLoading = true;

getDynamicForm({ bookingId: this.selectedBookingId })
    .then(result => {

        this.recordType = result.recordType;

        // ✅ FIRST map fields
this.dynamicFields = result.fields.map(f => {
    const type = (f.type || '').toLowerCase();
    console.log('FIELD:', f.label, f.type);
    console.log('MULTI FIELD:', f.apiName, f.options);
   // let value = f.value;
let value = f.value;

// 🔥 CLEAR DATE FIELDS (IMPORTANT)
const apiName = f.apiName;

if (
    apiName === 'Event_Date__c' ||
    apiName === 'Guest_arrival_time__c' ||
    apiName === 'Guest_departure_time__c'
) {
    value = null;
}
    // 🔥 FIX MULTI PICKLIST VALUE
    if (type === 'multipicklist') {
        value = value ? value.split(';') : [];
    }

    return {
        ...f,
        value: value, // ✅ important
        isText: type === 'string',
        isNumber: type === 'double' || type === 'integer',
        isDate: type === 'date',
        isDateTime: type === 'datetime',
        isMultiPicklist: type === 'multipicklist',
isPicklist: type === 'picklist',
isTextarea: type === 'textarea' && !['multipicklist','picklist'].includes(type)
    };
});


        // ✅ THEN group them
       // this.sections = this.groupFields(this.dynamicFields);
       this.sections = [
    {
        label: 'Enquiry Details',
        fields: this.dynamicFields
    }
];
        this.showReorderModal = true;
        this.isLoading = false;
        console.log('FIELDS:', this.dynamicFields);
console.log('SECTIONS:', this.sections);
    })
        .catch(error => {
         console.error('REORDER ERROR FULL:', error);
console.error('ERROR BODY:', error?.body);
            this.isLoading = false;

            Toast.show({
                label: 'Error',
                message: error?.body?.message || 'Failed to load form',
                variant: 'error'
            });
        });
}


   connectedCallback() {
    this.loadEvents();

    // 🔥 Add global click listener
    this.handleOutsideClick = this.handleOutsideClick.bind(this);
    document.addEventListener('click', this.handleOutsideClick);
}

disconnectedCallback() {
    document.removeEventListener('click', this.handleOutsideClick);
}

handleOutsideClick(event) {
    const dropdown = this.template.querySelector('.custom-dropdown');

    // If click is OUTSIDE component → close all menus
    if (!this.template.contains(event.target)) {
        this.closeAllMenus();
    }
}

closeAllMenus() {
    this.events = this.events.map(e => ({
        ...e,
        showMenu: false
    }));
}

    loadEvents() {
        this.isLoading = true;
        getPastEvents({ pageNumber: this.pageNumber, pageSize: this.pageSize })
            .then(result => {
                this.events = result.events.map(wrapper => {
                const event = wrapper.record;

                return {
                    ...event,
                    isRated: wrapper.isRated,   // 🔥 IMPORTANT
                    ratingLabel: wrapper.isRated ? 'Edit Rating' : 'Rate Staff',
                     showMenu: false,
                    formattedDate: this.formatDate(event.Event_Date__c),
                       // 🔥 ADD THESE TWO LINES
    formattedArrival: this.formatDateTimeLocal(event.Guest_arrival_time__c),
    formattedDeparture: this.formatDateTimeLocal(event.Guest_departure_time__c),

                    formattedAmount: this.formatCurrency(event.Order_Total_Amount__c),
                    venueFirstLine: this.getVenueFirstLine(event.Venue_Address__c),
                    venueSecondLine: this.getVenueSecondLine(event.Venue_Address__c),
                     hasFeedback: wrapper.hasFeedback, // 🔥 ADD THIS FROM APEX
                    feedbackLabel: wrapper.hasFeedback ? 'Edit Feedback' : 'Give Feedback',
                };
            });
                this.totalRecords = result.totalRecords;
                this.totalPages = result.totalPages;
                this.error = undefined;
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error.body.message;
                this.events = [];
                this.isLoading = false;
            });
    }

    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        return date.toLocaleDateString('en-US', { 
            year: 'numeric', 
            month: 'short', 
            day: 'numeric' 
        });
    }

    
handleRating(event) {
    console.log('CLICKED RATE BUTTON');

    this.selectedBookingId = event.currentTarget.dataset.id;

    this.isLoading = true;

    getStaffByBooking({ bookingId: this.selectedBookingId })
        .then(data => {

           this.staffList = data.map(s => ({
    id: s.id,
    name: s.name,
    rating: s.rating || 0,
    comment: s.comment || '',
    photoUrl: s.photoUrl,
    initial: s.name ? s.name.charAt(0).toUpperCase() : ''
}));
            // 🔥 update button label
            const isRated = this.staffList.some(s => s.rating > 0);

            this.events = this.events.map(e => {
                if (e.Id === this.selectedBookingId) {
                    return { ...e, isRated: isRated };
                }
                return e;
            });

            this.showRatingModal = true;

            setTimeout(() => {
                this.updateStars();
            }, 0);

            this.isLoading = false;
        })
        .catch(error => {
            console.error('ERROR:', JSON.stringify(error));
            this.isLoading = false;
        });
}

handleRatingChange(event) {
    const staffId = event.target.dataset.id;
    const value = event.detail.value;

    this.staffList = this.staffList.map(s => {
        if (s.id === staffId) {
            return { ...s, rating: value };
        }
        return s;
    });
}

handleCommentChange(event) {
    const staffId = event.target.dataset.id;
    const value = event.target.value;

    this.staffList = this.staffList.map(s => {
        if (s.id === staffId) {
            return { ...s, comment: value };
        }
        return s;
    });
}

handleStarClick(event) {
    const staffId = event.target.dataset.id;
    const rating = parseInt(event.target.dataset.value);

    this.staffList = this.staffList.map(s => {
        if (s.id === staffId) {
            return { ...s, rating: rating };
        }
        return s;
    });

    this.updateStars();
}

generateStars(value) {
    const rating = parseInt(value) || 0; // 🔥 FIX

    let stars = [];

    for (let i = 1; i <= 5; i++) {
        stars.push({
            value: i,
            class: i <= rating ? 'star filled' : 'star'
        });
    }

    return stars;
}

updateStars() {
    this.staffList = this.staffList.map(s => {
        let stars = [];

        for (let i = 1; i <= 5; i++) {
            stars.push({
                value: i,
                class: i <= s.rating ? 'star filled' : 'star'
            });
        }

        return { ...s, stars };
    });
}

closeRatingModal() {
    this.showRatingModal = false;
}

submitRatings() {

    
const invalid = this.staffList.some(s => !s.rating || s.rating === 0);

if (invalid) {
    Toast.show({
    label: 'Validation Error',
    message: 'Please provide rating for all staff',
    variant: 'error'
});
    return;
}


    const payload = this.staffList.map(s => ({
        bookingId: this.selectedBookingId,
        staffId: s.id,
        rating: s.rating,
        comment: s.comment
    }));

   saveRatings({ ratingsJson: JSON.stringify(payload) })
        .then(() => {
            Toast.show({
    label: 'Success',
    message: 'Ratings submitted successfully',
    variant: 'success'
});
            this.closeRatingModal();
        })
        .catch(error => {
    console.error('FULL ERROR:', JSON.stringify(error));

    let message = 'Error saving ratings';

    if (error.body) {
        if (error.body.message) {
            message = error.body.message;
        } else if (error.body.pageErrors && error.body.pageErrors.length) {
            message = error.body.pageErrors[0].message;
        } else if (error.body.fieldErrors) {
            message = JSON.stringify(error.body.fieldErrors);
        }
    }

    Toast.show({
    label: 'Error',
    message: message,
    variant: 'error'
});
});
}
    formatCurrency(amount) {
        if (!amount) return '$0.00';
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(amount);
    }

    getVenueFirstLine(address) {
        if (!address) return '';
        const lines = address.split('\n');
        return lines[0] || '';
    }

    getVenueSecondLine(address) {
        if (!address) return '';
        const lines = address.split('\n');
        return lines.slice(1).join(' ') || '';
    }

   handleViewDetails(event) {
    const recordId = event.currentTarget.dataset.id;
       console.log('🔍 View Details clicked for Record Id:', recordId);

        // Dispatch custom event to parent component
        const viewDetailsEvent = new CustomEvent('viewdetails', {
            detail: { recordId: recordId,
        type: 'PAST' },
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(viewDetailsEvent);
    }

    handlePrevious() {
        if (this.pageNumber > 1) {
            this.pageNumber--;
            this.loadEvents();
        }
    }

    handleNext() {
        if (this.pageNumber < this.totalPages) {
            this.pageNumber++;
            this.loadEvents();
        }
    }

    get isPreviousDisabled() {
        return this.pageNumber <= 1;
    }

    get isNextDisabled() {
        return this.pageNumber >= this.totalPages;
    }

    get showPagination() {
        return this.totalRecords > this.pageSize;
    }

    get paginationInfo() {
        const start = (this.pageNumber - 1) * this.pageSize + 1;
        const end = Math.min(this.pageNumber * this.pageSize, this.totalRecords);
        return `Showing ${start}-${end} of ${this.totalRecords}`;
    }

   /* handleReorder(event) {
    this.selectedBookingId = event.currentTarget.dataset.id;

    this.isLoading = true;

   getBookingDetails({ bookingId: this.selectedBookingId })
    .then(result => {

        const data = result.booking;
        this.recordType = result.recordType;

        this.occasion = data.Occasion__c;
        this.guests = data.Number_of_Guests__c;
        this.venue = data.Venue_Address__c;

        this.arrivalDateTime = this.formatDateTime(data.Guest_Arrival_Time__c);
        this.departureDateTime = this.formatDateTime(data.Guest_Departure_Time__c);

        this.showReorderModal = true;
        this.isLoading = false;
    });
}*/

get isCoffeeCart() {
    return this.recordType === 'Coffee_Cart';
}

get isRegularEvent() {
    return this.recordType !== 'Coffee_Cart';
}

closeModal() {
    this.showReorderModal = false;
}
handleDynamicChange(event) {
    const field = event.target.dataset.field;

    let value;

    // 🔥 Multi-select picklist
    if (event.detail && event.detail.value) {
        value = event.detail.value;   // array
    } else {
        value = event.target.value;   // normal fields
    }

    this.dynamicFields = this.dynamicFields.map(f => {
        if (f.apiName === field) {
            return { ...f, value };
        }
        return f;
    });
}
validateFields() {
    let isValid = true;

    this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea')
        .forEach(field => {
            if (!field.checkValidity()) {
                field.reportValidity();
                isValid = false;
            }
        });

    return isValid;
}

handleSubmit() {

    console.log('SUBMIT CLICKED');

    const missing = this.dynamicFields.some(f =>
    f.required && (!f.value || f.value.length === 0)
);

if (missing) {
    Toast.show({
        label: 'Validation Error',
        message: 'Please fill all required fields',
        variant: 'error'
    });
    return;
}

    const payload = {};

    this.dynamicFields.forEach(f => {
     if (f.isDateTime && f.value) {
    payload[f.apiName] = f.value.replace('T', ' ').substring(0, 19);
} else if (Array.isArray(f.value)) {
    payload[f.apiName] = f.value.join(';');
} else {
    payload[f.apiName] = f.value;
}
    });

    

    payload.bookingId = this.selectedBookingId;

    console.log('PAYLOAD:', JSON.stringify(payload));

    createEnquiry({
        dataJson: JSON.stringify(payload)
    })
    .then(() => {
        Toast.show({
            label: 'Success',
            message: 'Enquiry created successfully',
            variant: 'success'
        });
        this.closeModal();
    })
    .catch(error => {
        console.error('ERROR:', JSON.stringify(error));

        let message = 'Something went wrong. Please contact the admin.';

        if (error.body) {
            if (error.body.message) {
                //message = error.body.message;
                console.error('Error1:', error.body.message);
            } else if (error.body.pageErrors?.length) {
                //message = error.body.pageErrors[0].message;
                console.error('Error2:', error.body.pageErrors[0].message);    
            }
        }

        Toast.show({
            label: 'Error',
            message: message,
            variant: 'error'
        });
    });
}

/*handleSubmit() {
    console.log('Submitting...', this.arrivalDateTime, this.departureDateTime);
    const payload = {
    bookingId: this.selectedBookingId,
    occasion: this.occasion,
    guests: this.guests,
    venue: this.venue,
    eventDate: this.eventDate,
    arrivalDateTime: this.arrivalDateTime,
    departureDateTime: this.departureDateTime,

    // coffee fields
    coffeeStart: this.coffeeStart,
    coffeeEnd: this.coffeeEnd,
    budget: this.budget
};

   createEnquiry({
        dataJson: JSON.stringify(payload)
    })
    .then(() => {
        console.log('SUCCESS');
       Toast.show({
    label: 'Success',
    message: 'Enquiry created successfully',
    variant: 'success'
});
        this.closeModal();
    })
   .catch(error => {
    console.error('FULL ERROR:', JSON.stringify(error));

    let message = 'Something went wrong';

    if (error.body) {
        if (error.body.message) {
            message = error.body.message;
        } else if (error.body.pageErrors && error.body.pageErrors.length) {
            message = error.body.pageErrors[0].message;
        } else if (error.body.fieldErrors) {
            message = JSON.stringify(error.body.fieldErrors);
        }
    }

   Toast.show({
    label: 'Error',
    message: message,
    variant: 'error'
});
});
}*/
handleChange(event) {
    const label = event.target.label;

    if (label === 'Occasion') this.occasion = event.target.value;
    if (label === 'Guests') this.guests = event.target.value;
    if (label === 'Event Date') this.eventDate = event.target.value;
    if (label === 'Venue Address') this.venue = event.target.value;
    if (label === 'Guest Arrival Time') this.arrivalDateTime = event.target.value;
if (label === 'Guest Departure Time') this.departureDateTime = event.target.value;
}

formatDateTime(dt) {
    if (!dt) return null;
    return dt.slice(0,16); // removes seconds + Z
}

formatDateTimeLocal(dt) {
    if (!dt) return '';

    const date = new Date(dt);

    return new Intl.DateTimeFormat('en-AU', {
        timeZone: 'Australia/Sydney',
        day: 'numeric',
        month: 'numeric',
        year: 'numeric',
        hour: 'numeric',
        minute: '2-digit',
        hour12: true
    }).format(date);
}

handleActionSelect(event) {
    const action = event.currentTarget.dataset.action;
    const recordId = event.currentTarget.dataset.id;

    console.log('Action:', action, 'RecordId:', recordId);

    // close dropdown
    this.events = this.events.map(e => ({ ...e, showMenu: false }));

    switch (action) {
        case 'view':
            this.handleViewDetails({ currentTarget: { dataset: { id: recordId } } });
            break;

        case 'reorder':
            this.handleReorder({ currentTarget: { dataset: { id: recordId } } });
            break;

        case 'rating':
            this.handleRating({ currentTarget: { dataset: { id: recordId } } });
            break;

        case 'feedback':
            this.handleFeedback({ currentTarget: { dataset: { id: recordId } } });
            break;
    }
}

handleFeedbackStarClick(event) {
    const field = event.target.dataset.field;   // service / food / experience
    const value = parseInt(event.target.dataset.value);

    this.feedback[field] = value;

    // regenerate stars
    this.feedback[`${field}Stars`] = this.generateStars(value);
}

closeFeedbackModal() {
    this.showFeedbackModal = false;
}
handleFeedback(event) {
    this.selectedBookingId = event.currentTarget.dataset.id;
    this.isLoading = true;

    getFeedback({ bookingId: this.selectedBookingId })
        .then(data => {

            let feedbackObj;

            if (data) {
                feedbackObj = {
                    id: data.id,
                    bookingId: data.bookingId,
                    service: data.service || 0,
                    food: data.food || 0,
                    experience: data.experience || 0,
                    comments: data.comments || ''
                };
            } else {
                feedbackObj = {
                    id: null,
                    bookingId: this.selectedBookingId,
                    service: 0,
                    food: 0,
                    experience: 0,
                    comments: ''
                };
            }

            feedbackObj.service = parseInt(feedbackObj.service) || 0;
feedbackObj.food = parseInt(feedbackObj.food) || 0;
feedbackObj.experience = parseInt(feedbackObj.experience) || 0;

            // ✅ Build stars BEFORE assigning
            feedbackObj.serviceStars = this.generateStars(feedbackObj.service);
            feedbackObj.foodStars = this.generateStars(feedbackObj.food);
            feedbackObj.experienceStars = this.generateStars(feedbackObj.experience);
console.log('Stars:', feedbackObj.experienceStars);
            // ✅ Force reactivity
          this.feedback = {
    ...feedbackObj,
    serviceStars: feedbackObj.serviceStars || [],
    foodStars: feedbackObj.foodStars || [],
    experienceStars: feedbackObj.experienceStars || []
};
            // ✅ Force modal reopen (important)
            this.showFeedbackModal = true;
         
            this.isLoading = false;
        })
        .catch(error => {
            console.error(error);
            console.log('FEEDBACK DATA:', JSON.stringify(this.feedback));
           console.error('ERROR:', JSON.stringify(error));
            this.isLoading = false;
        });
}

handleFeedbackChange(event) {
    const field = event.target.name;
    this.feedback[field] = event.target.value;
}
submitFeedback() {

    if (!this.feedback.service || !this.feedback.food || !this.feedback.experience) {
        Toast.show({
    label: 'Validation Error',
    message: 'Please provide all ratings',
    variant: 'error'
});
        return;
    }

    const payload = {
        bookingId: this.selectedBookingId, 
        service: parseInt(this.feedback.service),
        food: parseInt(this.feedback.food),
        experience: parseInt(this.feedback.experience),
        comments: this.feedback.comments
    };

    saveFeedback({ dataJson: JSON.stringify(payload) })
        .then(() => {
            Toast.show({
    label: 'Success',
    message: 'Feedback submitted successfully',
    variant: 'success'
});
          this.showFeedbackModal = false;

// 🔥 REFRESH DATA FROM APEX
this.loadEvents();
        })
        .catch(error => {
    console.error('FULL ERROR:', JSON.stringify(error));

    let message = 'Error saving feedback';

    if (error.body) {
        if (error.body.message) {
            message = error.body.message;
        } else if (error.body.pageErrors && error.body.pageErrors.length) {
            message = error.body.pageErrors[0].message;
        } else if (error.body.fieldErrors) {
            message = JSON.stringify(error.body.fieldErrors);
        }
    }

   Toast.show({
    label: 'Error',
    message: message,
    variant: 'error'
});
});
}
}