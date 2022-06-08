import {Controller} from '@hotwired/stimulus'

export default class extends Controller {
    connect() {
        this.dragging = false;
    }
    static targets = ['left','right','dragbar']

    mousedown (){
    this.dragging=true;
    }

    mousemove (e){

        if (this.dragging){    
            this.leftTarget.style.width = `max(7em, ${e.clientX}px)`;
            this.rightTarget.style.width = `max(7em, calc(100vw - ${e.clientX}px))`;
        }
    }
    mouseup (){
    this.dragging=false;    
    }

}
