import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';

export default class NoteModal extends LightningElement {

   @api isUpdate = false;
   @api note = {};
   @api noteId;
   @api isOpen;

   @track noteTitle = '';
   @track noteDescription = '';
   @track objectId = null;  // to set the current object id
   @track isObject = false; // check either user open app in object or outside the object
   @track isAllFill = true; //to check either required fields are filled or note
   @track isSaving = false;  // to check is note saving 
   @track isSaved = false

   autoSaveInterval  //set interval
   tickTime

   @wire(CurrentPageReference) currentPageReference;


   get modalHeading() {
      return this.isUpdate ? 'Edit Note' : 'Add Note';
   }

   connectedCallback() {

      const { title } = this.note;

      if (title) {
         this.noteTitle = this.note.title || '';
         this.noteDescription = this.note.content || '';
         this.objectId = this.note?.objectId;
         this.isObject = !!this.note?.objectId;
         this.isAllFill = false;
      } else {
         this.objectId = this.currentPageReference?.attributes?.recordId;
      }


   }

   handleInputChange(event) {

      const field = event.target.dataset.id;
      if (field === 'title') {
         this.noteTitle = event.target.value;
      } else if (field === 'description') {
         this.noteDescription = event.target.value;
      }

      if (this.noteTitle.trim()) {
         this.isAllFill = false;
      } else {
         this.isAllFill = true;
      }

      this.handleSave();
   }

   handleClose() {

      this.dispatchEvent(new CustomEvent('close', {
         detail: {
            Id: this.noteId,
            title: this.noteTitle
         }
      }));

      this.noteDescription = '';
      this.noteTitle = '';
      this.objectId = null
      this.isObject = false;
      this.note = {};
   }

   handleSave() {

      if (!this.noteTitle.trim()) {
         this.showToast('Error', 'Title field is required.', 'error');
         return;
      }

      this.isSaving = true; // Show saving indicator
      this.isSaved = false; // Show note is saved

      // Clear the existing timeout before setting a new one
      if (this.autoSaveTimeout) {
         clearTimeout(this.autoSaveTimeout);
      }


      this.autoSaveTimeout = setTimeout(() => {
         this.dispatchEvent(new CustomEvent('save', {
            detail: {
               title: this.noteTitle,
               description: this.noteDescription,
               objectId: (this.objectId && this.isObject) ? this.objectId : ''
            }
         }));

         this.isSaving = false; // Hide saving indicator
         this.isSaved = true;   // Show tick icon
         if (this.tickTime) {
            clearTimeout(this.tickTime);
         }

         this.tickTime = setTimeout(() => {
            this.isSaved = false;
         }, 2000);
      }, 3000);
   }


   handleCheckboxChange() {
      this.isObject = !this.isObject;
      this.handleSave();
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
