import maplibre from 'maplibre-gl'
import consumer from 'channels/consumer'

class PresenceTracker {
  static messageDelay = 100 // milliseconds
  static timeoutDelay = 10 * 1000 // milliseconds

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
    this.marker = new maplibre.Marker({ element: this.el, anchor: 'top-left' }).setLngLat(lngLat)
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

    this.moveTo(lngLat)
    this.lost = false
  }

  moveTo (lngLat) {
    const marker = this.marker
    const old = marker.getLngLat()
    const target = lngLat
    const start = performance.now()

    function animate (timestamp) {
      if (timestamp - start < PresenceTracker.messageDelay) {
        const ratio = (timestamp - start) / PresenceTracker.messageDelay
        const cosRatio = (1 - Math.cos(ratio * Math.PI)) / 2
        const lng = cosRatio * target.lng + (1 - cosRatio) * old.lng
        const lat = cosRatio * target.lat + (1 - cosRatio) * old.lat
        marker.setLngLat([lng, lat])
        window.requestAnimationFrame(animate)
      } else {
        marker.setLngLat(target)
      }
    }

    window.requestAnimationFrame(animate)
  }

  resetTimeout (trackers) {
    if (this.timer) {
      clearInterval(this.timer)
    }
    this.timer = window.setTimeout(() => this.timeout(trackers), PresenceTracker.timeoutDelay)
  }
}

class PresenceTrackers {
  constructor (map, mapId) {
    this.trackers = new Map()
    this.lastMoveSent = Date.now()
    this.map = map
    this.#initActionCable(mapId)
  }

  mousemove ({ lngLat }) {
    if (Date.now() - this.lastMoveSent > PresenceTracker.messageDelay) {
      this.channel.mouse_moved(lngLat)
      this.lastMoveSent = Date.now()
    }
  }

  #upsert (data) {
    let tracker
    if (this.trackers.has(data.cid)) {
      tracker = this.trackers.get(data.cid)
      tracker.update(data)
    } else {
      tracker = new PresenceTracker(data)
      tracker.marker.addTo(this.map)
      this.trackers.set(data.cid, tracker)
    }
    tracker.resetTimeout(this.trackers)
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
