import { LightningElement, api, track } from 'lwc';
import getEligibleStaff from '@salesforce/apex/PreferredStaffService.getEligibleStaff';
import markPreferred from '@salesforce/apex/PreferredStaffService.markPreferred';
import Toast from 'lightning/toast';
import getPreferredStaff from '@salesforce/apex/PreferredStaffService.getPreferredStaff';
import removePreferredBulk from '@salesforce/apex/PreferredStaffService.removePreferredBulk';

export default class PreferredStaffSelector extends LightningElement {

 
@track preferredStaffList = [];
    @track staffList = [];
   _recordId;

preferredPage = 1;
preferredPageSize = 5;
preferredTotalRecords = 0;

@api
set recordId(value) {
    this._recordId = value;
    console.log('CHILD received recordId:', value); 
    if (value) {
        this.page = 1;
        this.loadData();
        this.loadPreferredStaff(); // 👈 ADD THIS
    }
}

handleImageLoad(event) {
    event.target.classList.remove('hidden');
}

selectedPreferredIds = new Set();

handleImageError(event) {
    const img = event.target;

    // prevent infinite loop
    img.onerror = null;

    img.src = '/resource/defaultAvatar';
}

getInitial(name) {
    return name ? name.charAt(0).toUpperCase() : '';
}

getStars(rating) {
    if (!rating) return '☆☆☆☆☆';

    const full = Math.floor(rating);
    return '★'.repeat(full) + '☆'.repeat(5 - full);
}

get hasPreferred() {
    return this.preferredStaffList && this.preferredStaffList.length > 0;
}

handleRemovePreferred(event) {
    const staffId = event.target.dataset.id;

    removePreferred({
        contactId: this.recordId,
        staffId: staffId
    })
    .then(() => {
        this.showToast('Success', 'Removed from preferred', 'success');

        this.loadPreferredStaff();
        this.loadData();
    })
    .catch(error => {
        console.error(error);
    });
}

loadPreferredStaff() {
    const offset = (this.preferredPage - 1) * this.preferredPageSize;

    getPreferredStaff({
        contactId: this.recordId,
        pageSize: this.preferredPageSize,
        offsetSize: offset
    })
    .then(result => {
        console.log('RESULT:', JSON.stringify(result));
     setTimeout(() => {
    this.preferredStaffList = result.records.map(p => ({
        ...p,
        initial: this.getInitial(p.staffName),
        stars: this.getStars(p.avgRating),
        roundedRating: p.avgRating ? Math.floor(p.avgRating) : null
    }));
}, 100);
        console.log('photo url', this.preferredStaffList);
        this.preferredTotalRecords = result.totalCount;

    })
    .catch(error => {
        console.error(error);
    });
}

handlePreferredNext() {
    this.preferredPage++;
    this.loadPreferredStaff();
}

handlePreferredPrev() {
    this.preferredPage--;
    this.loadPreferredStaff();
}

get preferredTotalPages() {
    return Math.ceil(this.preferredTotalRecords / this.preferredPageSize);
}

get isPreferredPrevDisabled() {
    return this.preferredPage === 1;
}

get isPreferredNextDisabled() {
    return this.preferredPage >= this.preferredTotalPages;
}

get preferredStartRecord() {
    return (this.preferredPage - 1) * this.preferredPageSize + 1;
}

get preferredEndRecord() {
    return Math.min(
        this.preferredPage * this.preferredPageSize,
        this.preferredTotalRecords
    );
}

get recordId() {
    return this._recordId;
}
get hasRecords() {
    return this.staffList && this.staffList.length > 0;
}

    selectedStaffIds = new Set();

    page = 1;
    pageSize = 5;
    totalRecords = 0;


loadData() {
    const offset = (this.page - 1) * this.pageSize;

    getEligibleStaff({
        contactId: this.recordId,
        pageSize: this.pageSize,
        offsetSize: offset
    })
    .then(result => {

        this.staffList = result.records.map(s => {
            return {
                ...s,
                initial: this.getInitial(s.staffName),
                stars: this.getStars(s.avgRating),
                roundedRating: s.avgRating ? Math.floor(s.avgRating) : 0
            };
        });

        this.totalRecords = result.totalCount;

    })
    .catch(error => {
        console.error(error);
    });
}

    handleSelect(event) {
        const id = event.target.value;

        let updatedSet = new Set(this.selectedStaffIds);

        if (event.target.checked) {
            updatedSet.add(id);
        } else {
            updatedSet.delete(id);
        }

        this.selectedStaffIds = updatedSet; // 👈 IMPORTANT
    }

    get isDisabled() {
        console.log('Selected size:', this.selectedStaffIds.size);
        return this.selectedStaffIds.size === 0;
    }

    get buttonClass() {
        return this.selectedStaffIds.size === 0 
            ? 'btn disabled-btn' 
            : 'btn active-btn';
    }

    handleMarkPreferred() {
        markPreferred({
            contactId: this.recordId,
            staffIds: Array.from(this.selectedStaffIds)
        })
        .then(() => {
            this.showToast('Success', 'Staff marked as preferred', 'success');

            // ✅ reset selection properly
            this.selectedStaffIds = new Set();

            // ✅ refresh BOTH sections
            this.loadData();              // eligible staff
            this.loadPreferredStaff();    // 👈 ADD THIS

        })
        .catch(error => {
            console.error(error);
        });
    }

    handleNext() {
        this.page++;
        this.loadData();
    }

    handlePrev() {
        this.page--;
        this.loadData();
    }

    get isRemoveDisabled() {
    return this.selectedPreferredIds.size === 0;
}

get removeButtonClass() {
    return this.selectedPreferredIds.size === 0
        ? 'btn disabled-btn'
        : 'btn active-btn';
}

handleRemoveSelected() {
    removePreferredBulk({
        contactId: this.recordId,
        staffIds: Array.from(this.selectedPreferredIds)
    })
    .then(() => {
        this.showToast('Success', 'Removed from preferred', 'success');

        this.selectedPreferredIds = new Set();
        this.preferredPage = 1; // reset page
        this.loadPreferredStaff();
        this.loadData();
    })
    .catch(error => {
        console.error(error);
    });
}

    handlePreferredSelect(event) {
    const id = event.target.value;

    let updated = new Set(this.selectedPreferredIds);

    if (event.target.checked) {
        updated.add(id);
    } else {
        updated.delete(id);
    }

    this.selectedPreferredIds = updated;
}

    showToast(title, message, variant) {
    Toast.show({
        label: title,
        message: message,
        variant: variant
    });
}

    get isPrevDisabled() {
        return this.page === 1;
    }

    get isNextDisabled() {
    return this.page >= this.totalPages;
}

    get startRecord() {
        return (this.page - 1) * this.pageSize + 1;
    }

    get endRecord() {
        return Math.min(this.page * this.pageSize, this.totalRecords);
    }

    get totalPages() {
        return Math.ceil(this.totalRecords / this.pageSize);
    }
}