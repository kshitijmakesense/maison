import { LightningElement, track } from 'lwc';

export default class MaisonReorderPage extends LightningElement {

    @track bookings = [];

    connectedCallback() {
        this.loadBookings();
    }

    // 🔹 Replace with Apex later
    loadBookings() {
        this.bookings = [
            {
                id: '1',
                name: 'Birthday Event',
                date: '12 Jan 2026',
                guests: 50,
                amount: 1200,
                status: 'Completed'
            },
            {
                id: '2',
                name: 'Corporate Lunch',
                date: '25 Feb 2026',
                guests: 30,
                amount: 800,
                status: 'Completed'
            }
        ];
    }

    get isEmpty() {
        return this.bookings.length === 0;
    }

    handleReorder(event) {
        const bookingId = event.currentTarget.dataset.id;

        console.log('Reordering booking:', bookingId);

        // 🔹 Future: Call Apex here
        // cloneBooking({ bookingId })

        this.showToast('Success', 'Reorder initiated successfully', 'success');
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(evt);
    }
}