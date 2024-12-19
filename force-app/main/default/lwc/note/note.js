import { api, LightningElement } from 'lwc';

export default class Note extends LightningElement {
   @api note;

   get backgroundColor() {
      return this.note.Color_Code__c;
   }

   renderedCallback() {
      // Apply the dynamic background color to the root element
      const noteElement = this.template.querySelector('.card');
      if (noteElement) {
         noteElement.style.backgroundColor = this.backgroundColor;
      }
   }

   // Dispatch delete event
   handleDelete() {
      const deleteEvent = new CustomEvent('delete', {
         detail: this.note.Id
      });
      this.dispatchEvent(deleteEvent);
   }

   // Dispatch edit event
   handleEdit() {
      const editEvent = new CustomEvent('edit', {
         detail: {
            title: this.note.Title__c,
            content: this.note.Content__c,
            objectId: this.note.ObjectId__c,
            color: this.note.Color_Code__c,
            Id: this.note.Id
         }
      });
      this.dispatchEvent(editEvent);
   }

   handleShare() {
      const shareEvent = new CustomEvent('share', {
         detail: this.note.Id
      });

      this.dispatchEvent(shareEvent);
   }

   formatDate(dateString) {
      if (!dateString) return '';
      const date = new Date(dateString);
      return date.toLocaleDateString();
   }
}
