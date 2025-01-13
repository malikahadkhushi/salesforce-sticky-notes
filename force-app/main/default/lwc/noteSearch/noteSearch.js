import { LightningElement } from 'lwc';

export default class NoteSearch extends LightningElement {

   searchText = '';

   searchNoteHandler = (event) => {
      const value = event.target.value;
      value.trim() && this.debounce(value);
   }

   debounce = (text, delay = 1000) => {
      setTimeout(() => {
         const searchEvent = new CustomEvent('search', {
            detail: text
         });

         this.dispatchEvent(searchEvent);
      }, delay);
   }
}