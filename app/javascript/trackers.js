import maplibre from 'maplibre-gl'

class Tracker {
    constructor({name, lngLat, sessionId}) {
        this.name = name ? name : 'Anonymous'
        this.sessionId = sessionId
        this.lost = false

        this.el = document.createElement('div')
        this.el.innerText = this.name

        this.marker = new maplibre.Marker(this.el).setLngLat(lngLat)
    }

    timeout(trackers) {
        if (this.lost) {
            this.marker.remove()
            trackers.delete(this.sessionId)
        }
        else {
            this.lost = true
            this.el.innerText = this.name + ' (lost)'
            this.resetTimeout(trackers)
        }
    }

    update({name, lngLat}) {
        this.name = name  ? name : 'Anonymous'
        this.el.innerText = this.name
        this.marker.setLngLat(lngLat)
        this.lost = false
    }

    resetTimeout(trackers) {
        if (this.timer) {
            clearInterval(this.timer)
        }
        this.timer = window.setTimeout( () => this.timeout(trackers), 10*1000);
    }
}

class Trackers {
    constructor(map) {
        this.trackers = new Map()
        this.map = map;
    }

    upsert(data) {
        if (this.trackers.has(data.sessionId)) {
            this.trackers.get(data.sessionId).update(data)
        } else {
            const tracker = new Tracker(data)
            tracker.marker.addTo(this.map)
            tracker.resetTimeout(this.trackers)
            this.trackers.set(data.sessionId, tracker)
        }
    }
}

export default Trackers
