import maplibre from 'maplibre-gl'

class Tracker {
  constructor ({ name, lngLat, sessionId }) {
    this.name = name || 'Anonymous'
    this.sessionId = sessionId
    this.lost = false

    this.el = document.createElement('div')
    this.el.className = 'tracker'
    this.el.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10">
            <path d="m0 10 v-10 h10" fill="transparent" stroke-width="5px" stroke="black" />
        </svg>
        <span></span>`
    this.setName(name)
    this.marker = new maplibre.Marker(this.el, { anchor: 'top-left' }).setLngLat(lngLat)
  }

  setName (name) {
    const el = this.el.getElementsByTagName('span')[0]
    el.innerText = name
  }

  timeout (trackers) {
    if (this.lost) {
      this.marker.remove()
      trackers.delete(this.sessionId)
    } else {
      this.lost = true
      this.setName(this.name + ' (lost)')
      this.resetTimeout(trackers)
    }
  }

  update ({ name, lngLat }) {
    this.name = name || 'Anonymous'
    this.setName(this.name)
    this.marker.setLngLat(lngLat)
    this.lost = false
  }

  resetTimeout (trackers) {
    if (this.timer) {
      clearInterval(this.timer)
    }
    this.timer = window.setTimeout(() => this.timeout(trackers), 10 * 1000)
  }
}

class Trackers {
  constructor (map) {
    this.trackers = new Map()
    this.map = map
  }

  upsert (data) {
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
