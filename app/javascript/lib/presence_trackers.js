import maplibre from 'maplibre-gl'
import consumer from 'channels/consumer'

class PresenceTracker {
  constructor ({ name, lngLat, cid }) {
    this.name = name || 'Anonymous'
    this.cid = cid
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
      trackers.delete(this.cid)
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

class PresenceTrackers {
  constructor (mapController) {
    this.trackers = new Map()
    this.lastMoveSent = Date.now()
    this.map = mapController.map
    this.#initActionCable(mapController.mapIdValue)
  }

  mousemove ({ lngLat }) {
    if (Date.now() - this.lastMoveSent > 20) {
      this.channel.mouse_moved(lngLat)
      this.lastMoveSent = Date.now()
    }
  }

  #upsert (data) {
    if (this.trackers.has(data.cid)) {
      this.trackers.get(data.cid).update(data)
    } else {
      const tracker = new PresenceTracker(data)
      tracker.marker.addTo(this.map)
      tracker.resetTimeout(this.trackers)
      this.trackers.set(data.cid, tracker)
    }
  }

  #initActionCable (mapId) {
    const _this = this
    this.cid = window.crypto.randomUUID()
    this.channel = consumer.subscriptions.create({ channel: 'PresenceTrackerChannel', map: mapId, cid: this.cid }, {
      connected () {
        console.log('PresenceTrackerChannel connected')
      },
      disconnected () {
        console.log('PresenceTrackerChannel disconnected')
      },
      received (data) {
        if (data.cid !== _this.cid) {
          _this.#upsert(data)
        }
      },
      mouse_moved (lngLat) {
        return this.perform('mouse_moved', { lngLat })
      }
    })
  }
}

export default PresenceTrackers
