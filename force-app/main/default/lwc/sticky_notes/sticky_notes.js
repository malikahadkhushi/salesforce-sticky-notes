import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

import getNotes from '@salesforce/apex/StickyAppController.getNotes';
import createNote from '@salesforce/apex/StickyAppController.createNote';
import updateNote from '@salesforce/apex/StickyAppController.updateNote';
import deleteNote from '@salesforce/apex/StickyAppController.deleteNote';
import sharedNotes from '@salesforce/apex/StickyAppController.sharedNotes';

export default class StickyNotes extends LightningElement {

   _stickyNotes = [];
   @track isModalOpen = false;
   @track isSelectionModal = false;
   @track isUpdate = false;
   @track isLoading = false;
   @track note = {};



   @track objectId;
   @track noteId; // use to store created note id 

   // Channels for Change Data Capture
   noteChannel = '/data/notes__ChangeEvent';
   sharingChannel = '/data/sharedNote__ChangeEvent';
   subscriptions = {};

   @wire(CurrentPageReference)
   setCurrentPageReference(pageRef) {
      const newObjectId = pageRef?.attributes?.recordId;
      if (this.objectId !== newObjectId) {
         this.objectId = newObjectId;
      }
      this.fetchNotes();
      this.subscribeToCDC(this.noteChannel);
      this.subscribeToCDC(this.sharingChannel);

   }


   disconnectedCallback() {
      this.unsubscribeFromCDC(this.noteChannel);
   }

   get stickyNotes() {
      return this._stickyNotes;
   }

   set stickyNotes(value) {
      this._stickyNotes = value;
   }


   subscribeToCDC(channel) {
      subscribe(channel, -1, (message) => {

         this.handleCDCEvent(channel, message);
      }).then((response) => {
         this.subscriptions[channel] = response;
         console.log(`Subscribed to ${channel} successfully:`, response);
      }).catch((error) => {
         console.error(`Error subscribing to ${channel}:`, error);
      });

   }

   unsubscribeFromCDC(channel) {
      if (!this.subscriptions[channel]) {
         console.warn(`No subscription found for channel: ${channel}`);
         return;
      }
      console.log("Unsubscribing from channel:", channel, this.subscriptions[channel]);
      unsubscribe(this.subscriptions[channel], (response) => {
         console.log(`Unsubscribed from ${channel} successfully:`, response);
      })
         .catch((error) => {
            console.error(`Error unsubscribing from ${channel}:`, error);
         });
   }


   // Handle CDC events based on the channel
   handleCDCEvent(channel, message) {
      const { data } = message;
      const changeType = data?.payload?.ChangeEventHeader?.changeType;

      if (channel === this.noteChannel) {
         this.handleNoteChangeEvent(data, changeType);
      } else if (channel === this.sharingChannel) {
         this.handleSharingChangeEvent(data, changeType);
      }
   }

   // Handle Note Change Event
   handleNoteChangeEvent(data, changeType) {
      if (changeType === 'UPDATE') {
         this.fetchNotes();
      }
   }

   // Handle Sharing Change Event
   handleSharingChangeEvent(data, changeType) {
      if (changeType === 'CREATE') {
         this.fetchNotes();
         this.showToast('Info', 'A note has been shared with you!', 'info');
      }
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
      console.log("close share modal");
      this.isSelectionModal = false;
      this.unsubscribeFromCDC(this.sharingChannel);

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
      getNotes({ objectId: this.objectId })
         .then((data) => {
            this.stickyNotes = data;

         })
         .catch((error) => {
            this.showToast('Error', 'Failed to retrieve notes: ' + error?.body?.message, 'error');
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
