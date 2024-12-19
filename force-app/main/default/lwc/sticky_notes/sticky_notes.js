import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';

import getNotes from '@salesforce/apex/StickyAppController.getNotes';
import createNote from '@salesforce/apex/StickyAppController.createNote';
import updateNote from '@salesforce/apex/StickyAppController.updateNote';
import deleteNote from '@salesforce/apex/StickyAppController.deleteNote';
import sharedNotes from '@salesforce/apex/StickyAppController.sharedNotes';

export default class StickyNotes extends LightningElement {

   @track stickyNotes = [];
   @track isModalOpen = false;
   @track isSelectionModal = false;
   @track isUpdate = false;
   @track isLoading = false;
   @track note = {};

   @track objectId;
   @track noteId; // use to store created note id 
   @wire(CurrentPageReference)
   setCurrentPageReference(pageRef) {
      const newObjectId = pageRef?.attributes?.recordId;
      if (this.objectId !== newObjectId) {
         this.objectId = newObjectId;
      }
      this.fetchNotes();
   }

   //  Open modal
   async openModal() {
      this.isModalOpen = true;
      await this.createNoteHandler();
   }

   openShareModal(event) {
      const Id = event.detail;
      this.noteId = Id;
      this.isSelectionModal = true;
   }

   closeShareModal() {
      this.isSelectionModal = false;
   }

   // Close modal
   async closeModal(event) {
      const { Id, title } = event.detail;
      this.isModalOpen = false;
      this.isUpdate = false;
      this.note = {};
      this.noteId = null

      if (!title.trim()) {
         await this.deleteHandler(Id)
      }
      this.fetchNotes();

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

   async createNoteHandler() {
      try {
         const note = await createNote({ title: "", content: "", objectId: this.objectId || "", code: "#ffeaa7" });
         this.noteId = note.Id;
      } catch (error) {
         console.log("Error", error?.message,);
      }
   }

   async deleteHandler(Id) {
      try {
         this.isLoading = true;
         await deleteNote({ Id });
         this.fetchNotes();
         this.isLoading = false;
      } catch (error) {
         console.log("error", error?.message);
         this.isLoading = false;
      }
   }

   // Save note on input after some time interval
   async handleSaveNote(event) {
      const { title, description, objectId, code } = event.detail;
      try {
         if (this.isUpdate || title || description) {
            await updateNote({ Id: this.noteId || this.note.Id, title, content: description, objectId, code });
         }
      } catch (error) {
         this.showToast('Error', 'Failed to update note: ' + error?.body?.message, 'error');
      }
   }

   // Delete note
   handleDeleteNote(event) {
      const Id = event.detail;
      this.deleteHandler(Id);
   }

   // Edit a note
   handleEditNote(event) {
      const { title, content, Id, objectId, color } = event.detail;
      this.isUpdate = true;

      this.isModalOpen = true;
      this.note = {
         title: title,
         content: content,
         Id: Id,
         objectId: objectId,
         color: color
      }
   }

   // sharing notes handler

   /**
    * 
    * @param {*} event 
    * shared note comes from selection modal  
    */
   handleShareNotes(event) {

      this.isLoading = true;
      const sharedNote = event.detail;

      sharedNotes({ data: sharedNote })
         .then((result) => {
            this.showToast('Success', 'Notes shared successfully!', 'success');
         })
         .catch((error) => {
            const errorMessage = error?.body?.message || 'An unknown error occurred';
            this.showToast('Error', `Failed to share notes: ${errorMessage}`, 'error');
         })
         .finally(() => {
            this.isLoading = false;
         });
   }

   async handleChangeColor(event) {
      try {
         const data = event.detail;
         const response = await updateNote({
            Id: this.noteId || this.note.Id,
            title: data.title,
            content: data.description,
            objectId: data.objectId,
            code: data.code
         });
      } catch (error) {
         console.log("Error", error);
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
