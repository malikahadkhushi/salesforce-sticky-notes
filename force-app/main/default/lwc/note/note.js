import { api, LightningElement } from 'lwc';

export default class Note extends LightningElement {
   @api note;

   // Dispatch delete event
   handleDelete() {
      const deleteEvent = new CustomEvent('delete', {
         detail: this.note.Id
      });
      this.dispatchEvent(deleteEvent);
   }

   handleEdit() {
      const editEvent = new CustomEvent('edit', {
         detail: {
            title: this.note.Title__c,
            content: this.note.Content__c,
            objectId: this.note.ObjectId__c,
            Id: this.note.Id
         }
      });
      this.dispatchEvent(editEvent);
   }

   formatDate(dateString) {
      if (!dateString) return '';
      const date = new Date(dateString);
      return date.toLocaleDateString();
   }
}
