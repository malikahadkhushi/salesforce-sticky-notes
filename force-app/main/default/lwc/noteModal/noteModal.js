import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { subscribe, unsubscribe, onError, setDebugFlag } from 'lightning/empApi';

import getColors from '@salesforce/apex/Color.getColors';

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
   @track isSaved = false;
   @track color;
   @track activeColor;
   @track colors = []


   autoSaveInterval  //set interval
   tickTime
   channelName = '/event/NoteUpdateEvent__e';
   subscription = null;


   @wire(CurrentPageReference) currentPageReference;

   // show colors list for notes
   renderedCallback() {
      this.handleActiveColor()
   }

   subscribeToEvent() {
      subscribe(this.channelName, -1, (message) => {
         this.handleNoteUpdate(message.data.payload);
      }).then((response) => {
         this.subscription = response;
         console.log('Subscribed to channel:', this.channelName);
      });
   }

   connectedCallback() {

      if (Object.keys(this.note).length) {
         this.subscribeToEvent();
      }

      this.getColorsHandler();
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

   disconnectedCallback() {
      unsubscribe(this.subscription, (response) => {
         console.log('Unsubscribed from channel:', response);
      });
   }

   handleNoteUpdate(payload) {

      this.noteTitle = payload.Title__c || this.noteTitle;
      this.noteDescription = payload.Content__c || this.noteDescription;
      this.color = payload.Color__c || this.color;
      this.activeColor = this.color;
      this.handleActiveColor();

   }

   handleActiveColor() {

      const colorBoxes = this.template.querySelectorAll('.color-box');
      const noteContainer = this.template.querySelector('.note-container');
      // Default to the first color if activeColor is not set
      const activeColor = this.activeColor || this.color;

      colorBoxes.forEach((box, index) => {

         const color = this.colors[index].code;

         // Apply styles to each color box
         box.style.backgroundColor = color;
         box.style.width = '13px';
         box.style.height = '13px';
         box.style.borderRadius = '100%';
         box.style.cursor = 'pointer';

         // Highlight the active color
         if (color === activeColor) {
            box.style.outline = '2px solid white';
         } else {
            box.style.outline = 'none';
         }

      });

      // Update the note container background color
      if (noteContainer) {
         noteContainer.style.backgroundColor = activeColor;
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

      setTimeout(() => {
         this.handleSave();
      }, 2000);
   }

   applyBold() {
      this.formatText('bold');
   }

   applyItalic() {
      this.formatText('italic');
   }

   applyUnderline() {
      this.formatText('underline');
   }

   applyStrike() {
      this.formatText('line-through');
   }

   formatText(style) {
      const textarea = this.template.querySelector('.note-textarea');
      const start = textarea.selectionStart;
      const end = textarea.selectionEnd;

      if (start === end) {
         // No text is selected, do nothing
         return;
      }

      const text = textarea.value;
      const selectedText = text.substring(start, end);

      // Apply the selected style
      let wrappedText;
      switch (style) {
         case 'bold':
            wrappedText = `<b>${selectedText}</b>`; // HTML bold
            break;
         case 'italic':
            wrappedText = `<i>${selectedText}</i>`; // HTML italic
            break;
         case 'underline':
            wrappedText = `<u>${selectedText}</u>`; // HTML underline
            break;
         case 'line-through':
            wrappedText = `<strike>${selectedText}</strike>`; // HTML strike-through
            break;
      }

      // Replace the selected text with the formatted text
      textarea.value = text.substring(0, start) + wrappedText + text.substring(end);

      // Update the description value to reflect the changes
      this.noteDescription = textarea.value;

      // Reset the cursor position
      textarea.setSelectionRange(start, start + wrappedText.length);
      textarea.focus();

      // If you want to render the formatted text in another element, you can use innerHTML
      const outputElement = this.template.querySelector('.note-textarea');
      if (outputElement) {
         outputElement.innerHTML = this.noteDescription; // Render formatted text as HTML
      }
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
               code: this.color || this.activeColor,
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
         }, 1000);
      }, 1000);

   }

   handleChangeColor(event) {

      const selectedColor = event.target.dataset.code;

      this.color = selectedColor;
      this.activeColor = selectedColor;

      this.handleActiveColor();


      // Example: Dispatch an event with the color value
      this.dispatchEvent(new CustomEvent('colorselect', {
         detail: {
            title: this.noteTitle,
            description: this.noteDescription,
            code: selectedColor,
            objectId: (this.objectId && this.isObject) ? this.objectId : ''
         }
      }));
   }

   handleCheckboxChange() {
      this.isObject = !this.isObject;
      this.handleSave();
   }

   async getColorsHandler() {
      try {

         const response = await getColors();
         this.colors = response;
         this.activeColor = this.note.color || this.colors[Math.floor(Math.random() * this.colors.length)]?.code;
         const color = response.find((color) => color.code == this.note.color);
         this.color = color?.code;

      } catch (error) {
         console.log("Error ", error?.message);
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
