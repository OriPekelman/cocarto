import {Controller} from '@hotwired/stimulus'

export default class extends Controller {
    connect() {
        console.log("isConnected");
        console.log(this.leftTarget);
        this.dragging = false;
    }
    static targets = ['left','right','dragbar']

    mousedown (){
    console.log("mousedown")
    this.dragging=true;
    }

    mousemove (e){

        if (this.dragging){    
            console.log("mousemove-left");
            this.leftTarget.style.width = `max(7em, ${e.clientX}px)`;
            this.rightTarget.style.width = `max(7em, calc(100vw - ${e.clientX}px))`;
        }
    }
    mouseup (){
    console.log("mouseup");
    this.dragging=false;    
    }

}
