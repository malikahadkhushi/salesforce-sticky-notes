import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';

export default class NoteModal extends LightningElement {

   @api isOpen = false;
   @api isUpdate = false;
   @api note = {};

   @track noteTitle = '';
   @track noteDescription = '';
   @track objectId = null;
   @track isObject = false;
   @track isAllFill = true;

   @wire(CurrentPageReference) currentPageReference;


   get modalHeading() {
      return this.isUpdate ? 'Edit Note' : 'Add Note';
   }

   connectedCallback() {

      const { title, content } = this.note;
      
      if (title && content) {
         this.noteTitle = this.note.title || '';
         this.noteDescription = this.note.content || '';
         this.isObject = !!this.note?.objectId;
         this.objectId = this.note?.objectId;
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

      if (this.noteTitle.trim() && this.noteDescription.trim()) { // disabled checkbox until all required fields are not filled
         this.isAllFill = false;
      } else {
         this.isAllFill = true;
      }

   }

   handleClose() {
      this.dispatchEvent(new CustomEvent('close'));
   }

   handleSave() {
      if (!this.noteTitle.trim() || !this.noteDescription.trim()) {
         this.showToast('Error', 'All fields are required.', 'error');
         return;
      }
      this.dispatchEvent(new CustomEvent('save', {
         detail: {
            title: this.noteTitle,
            description: this.noteDescription,
            objectId: (this.isObject && this.objectId) ? this.objectId : ''
         }
      }));

      this.noteDescription = '';
      this.noteTitle = '';
      this.objectId = null
      this.isObject = false;
      this.note = {};
   }

   handleCheckboxChange() {
      this.isObject = !this.isObject;
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
