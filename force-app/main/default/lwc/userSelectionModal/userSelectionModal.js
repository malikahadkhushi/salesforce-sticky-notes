import { LightningElement, track, api } from 'lwc';
import getUsers from '@salesforce/apex/StickyAppController.getUsers';

export default class UserSelectionModal extends LightningElement {

   @track users = [];
   @track selectedUsers = [];
   @track isDisabled = true;
   @track isLoading = false;

   @api noteId;


   connectedCallback() {
      this.fetchUsers();
   }

   closeModal() {
      const closeEvent = new CustomEvent('close', {});
      this.dispatchEvent(closeEvent);
      this.selectedUsers = []
   }

   handleCheckboxChange(event) {
      const Id = event.target.value;

      this.selectedUsers.includes(Id) ?
         this.selectedUsers = this.selectedUsers.filter(user => user !== Id) :
         this.selectedUsers.push(Id);

      this.selectedUsers.length > 0 ? this.isDisabled = false : this.isDisabled = true;

   }

   // Fetch Users from Apex Controller
   fetchUsers() {
      this.isLoading = true;
      getUsers()
         .then(result => {
            this.users = result;
            this.isLoading = false;
         })
         .catch(error => {
            this.isLoading = false;
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