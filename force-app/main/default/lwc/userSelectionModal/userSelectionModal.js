import { LightningElement, track, api } from 'lwc';
import getUsers from '@salesforce/apex/StickyAppController.getUsers';
import sendNotificationsToUsers from '@salesforce/apex/StickyAppController.sendNotificationsToUsers';
import sendEmailsToUsers from '@salesforce/apex/StickyAppController.sendEmailsToUsers';
export default class UserSelectionModal extends LightningElement {

   @track users = [];
   @track selectedUsers = [];
   @track isDisabled = true;
   @track isLoading = false;
   @track sendNotification = true;
   @track sendEmail = false;

   @api noteId;
   @api noteTitle


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

   handleSendNotificationChange(event) {
      this.sendNotification = event.target.checked;
      console.log("this.sendNotification", this.sendNotification);
   }

   // Handle "Send Email" checkbox change
   handleSendEmailChange(event) {
      this.sendEmail = event.target.checked;
      console.log("this.sendEmail", this.sendEmail);
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

   async shareNote() {

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

      if (this.sendNotification && this.sendEmail) {

         await sendNotificationsToUsers({
            userIds: this.selectedUsers,
            noteTitle: this.noteTitle
         });

         await sendEmailsToUsers({
            userIds: this.selectedUsers,
            noteTitle: this.noteTitle
         });

      } else if (this.sendNotification) {

         await sendNotificationsToUsers({
            userIds: this.selectedUsers,
            noteTitle: this.noteTitle
         });

      } else if (this.sendEmail) {

         await sendEmailsToUsers({
            userIds: this.selectedUsers,
            noteTitle: this.noteTitle
         });

      }

      this.closeModal();
      this.dispatchEvent(sharedNotesEvent);
   }
}