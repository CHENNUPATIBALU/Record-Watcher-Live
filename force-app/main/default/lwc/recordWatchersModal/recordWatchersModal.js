import { LightningElement, api, track } from 'lwc';

export default class RecordWatchersModal extends LightningElement {

    @api recordWatchers;

    handleClose(event){
        var customEvent = new CustomEvent('close');
        this.dispatchEvent(customEvent);
    }

    handleOpenUser(event){
        var userId = event.currentTarget.dataset.user;
        var customEvent = new CustomEvent('openuser', {
            detail: {
                userId: userId
            }
        });  
        this.dispatchEvent(customEvent);  
    }
}