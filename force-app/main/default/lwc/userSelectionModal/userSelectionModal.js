import { LightningElement, track, api } from 'lwc';
import getUsers from '@salesforce/apex/StickyAppController.getUsers';

export default class UserSelectionModal extends LightningElement {

   @track users = [];
   @track selectedUsers = [];

   @api noteId;

   columns = [
      { label: 'Name', fieldName: 'Name', type: 'text' },
   ];

   connectedCallback() {
      this.fetchUsers();
   }

   closeModal() {
      const closeEvent = new CustomEvent('close', {});
      this.dispatchEvent(closeEvent);
      this.selectedUsers = []
   }

   handleRowSelection(event) {

      const selectedRows = event.detail.selectedRows;
      this.selectedUsers = selectedRows.map(row => row.Id);

   }

   // Fetch Users from Apex Controller
   fetchUsers() {
      getUsers()
         .then(result => {
            this.users = result;
         })
         .catch(error => {
            console.error('Error fetching users:', error);
         });
   }

   shareNote() {

      const sharedNotes = this.selectedUsers.map((user) => {
         const obj = {
            User: user,
            Note: this.noteId
         }
         return obj;
      });

      const sharedNotesEvent = new CustomEvent('sharenotes', {
         detail: sharedNotes
      });

      this.closeModal();
      this.dispatchEvent(sharedNotesEvent);
   }
}