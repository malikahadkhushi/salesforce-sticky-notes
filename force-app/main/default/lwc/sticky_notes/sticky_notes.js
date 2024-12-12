import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';

import getNotes from '@salesforce/apex/StickyAppController.getNotes';
import createNote from '@salesforce/apex/StickyAppController.createNote';
import updateNote from '@salesforce/apex/StickyAppController.updateNote';
import deleteNote from '@salesforce/apex/StickyAppController.deleteNote';

export default class StickyNotes extends LightningElement {
   @track stickyNotes = [];
   @track isModalOpen = false;
   @track isUpdate = false;
   @track isLoading = false;
   @track note = {};

   @track objectId;

   @wire(CurrentPageReference)
   setCurrentPageReference(pageRef) {
      const newObjectId = pageRef?.attributes?.recordId;
      if (this.objectId !== newObjectId) {
         this.objectId = newObjectId;
      }
      this.fetchNotes();
   }

   //  Open modal
   openModal() {
      this.isModalOpen = true;
   }

   // Close modal
   closeModal() {
      this.isModalOpen = false;
      this.isUpdate = false;
      this.note = {};
   }

   // Fetch notes from Apex
   fetchNotes() {
      this.isLoading = true;
      getNotes({ objectId: this.objectId })
         .then((data) => {
            this.stickyNotes = data;
            this.isLoading = false;
         })
         .catch((error) => {
            this.showToast('Error', 'Failed to retrieve notes: ' + error?.body?.message, 'error');
            this.isLoading = false;

         });

   }

   // Save note (create or update)
   handleSaveNote(event) {

      this.isLoading = true;
      const { title, description, objectId } = event.detail;

      if (this.isUpdate) {
         updateNote({ Id: this.note.Id, title, content: description, objectId })
            .then(() => {
               this.showToast('Success', 'Note updated successfully!', 'success');
               this.fetchNotes();
               this.isLoading = false;

            })
            .catch((error) => {
               this.showToast('Error', 'Failed to update note: ' + error?.body?.message, 'error');
               this.isLoading = false;

            });
      } else {
         createNote({ title, content: description, objectId })
            .then(() => {
               this.showToast('Success', 'Note created successfully!', 'success');
               this.fetchNotes();
               this.isLoading = false;

            })
            .catch((error) => {
               this.showToast('Error', 'Failed to create note: ' + error?.body?.message, 'error');
               this.isLoading = false;

            });
      }

      this.closeModal();
   }

   // Delete note
   handleDeleteNote(event) {
      this.isLoading = true;
      const Id = event.detail;
      deleteNote({ Id })
         .then(() => {
            this.showToast('Success', 'Note deleted successfully!', 'success');
            this.fetchNotes();
            this.isLoading = false;
         })
         .catch((error) => {
            this.showToast('Error', 'Failed to delete note: ' + error?.body?.message, 'error');
            this.isLoading = false;

         });
   }



   //    // Edit a note
   handleEditNote(event) {
      const { title, content, Id, objectId } = event.detail;
      this.isUpdate = true;
      this.isModalOpen = true;
      this.note = {
         title: title,
         content: content,
         Id: Id,
         objectId: objectId
      }
   }


   showToast(title, message, variant) {
      const event = new ShowToastEvent({
         title,
         message,
         variant
      });
      this.dispatchEvent(event);
   }
}
