/* global ResizeObserver */
import { newMap, geocoderApi, newGeolocateControl } from 'lib/map_helpers'
import MapboxDraw from '@mapbox/mapbox-gl-draw'
import MaplibreGeocoder from '@maplibre/maplibre-gl-geocoder'
import maplibregl from 'maplibre-gl'
import PresenceTrackers from 'lib/presence_trackers'
import * as modes from 'lib/modes'

class MapState {
  constructor ({ target, mapId, lng, lat, zoom, leftToolbar, rightToolbar, style }) {
    this.map = newMap(target, [lng, lat], zoom, style)
    this.layers = {}
    this.mode = modes.DEFAULT
    this.style = style

    this.draw = new MapboxDraw({
      displayControlsDefault: false,
      userProperties: true
    })
    this.map.addControl(this.draw)

    const resizeObserver = new ResizeObserver(() => this.map.resize())
    resizeObserver.observe(target)

    rightToolbar.appendChild(newGeolocateControl().onAdd(this.map))
    rightToolbar.appendChild(new maplibregl.NavigationControl({ showCompass: false }).onAdd(this.map))
    leftToolbar.appendChild(new MaplibreGeocoder(geocoderApi, { maplibregl }).onAdd(this.map))

    this.trackers = new PresenceTrackers(this.map, mapId)

    this.map.on('load', e => { target.dataset.loaded = 'loaded' }) // System tests: Avoid interacting with the map before it's ready
    this.map.on('draw.create', ({ features }) => this.#featureCreated(features[0]))
    this.map.on('draw.update', ({ features }) => this.#featureUpdated(features[0]))
    this.map.on('mousemove', e => this.trackers.mousemove(e))
    this.map.on('mouseup', e => this.#editFeature(e))
    this.activeFeature = null
  }

  setMode (mode, args) {
    switch (mode) {
      case modes.DEFAULT:
        this.#unsetActive()
        this.draw.deleteAll()
        this.#mapSelectionChanged([])
        this.currentFeatureId = null;
        break
      case modes.EDIT_FEATURE:
        this.draw.deleteAll()
        this.#mapSelectionChanged(args.features)
        this.currentFeatureId = args.featureId
        this.map.doubleClickZoom.disable();
        break
      case modes.ADD_FEATURE:
        this.draw.changeMode(this.drawMode)
        break
      case modes.HOVER_FEATURE:
        this.#unsetActive()
        this.#setActive(args, 'hover')
        break
    }

    if (!modes.validModes.includes(mode)) {
      console.error(`Unknown mode ${mode}, previous mode ${this.mode}`)
      return
    }
    console.debug(`Switch from mode ${this.mode} to mode ${mode}`)
    this.mode = mode

    switch (mode) {
      case modes.DEFAULT:
        this.draw.deleteAll()
        this.#mapSelectionChanged([])
        break
      case modes.EDIT_FEATURE:
        this.draw.deleteAll()
        this.#mapSelectionChanged(args.features)
        this.currentFeatureId = args.featureIid
        break
      case modes.ADD_FEATURE:
        this.draw.changeMode(this.drawMode)
        break
    }
  }

  getMap () {
    return this.map
  }

  getMode () {
    return this.mode
  }

  getImage () {
    return this.map.getCanvas().toDataURL()
  }

  getCurrentView () {
    return {
      zoom: this.map.getZoom(),
      ...this.map.getCenter()
    }
  }

  setVisibleBounds (bounds) {
    this.map.fitBounds(bounds, { padding: 40, maxZoom: 17 })
  }

  setSelectedFeature (featureId) {
    // TODO: we want just a hover state
    // TODO: this should be a mode change
    this.draw.changeMode('simple_select', { featureIds: [featureId] })
  }

  setActiveLayer ({ geometryType, layerController }) {
    this.currentLayerController = layerController
    this.drawMode = `draw_${geometryType}`
  }

  refresh (layer) {
    const cache = this.map.style.sourceCaches[layer]
    cache.clearTiles()
    cache.update(this.map.transform)
  }

  registerLayer ({ layerId, geometryType }) {
    this.map.setStyle(this.style, { diff: true })
    this.layers[layerId] = geometryType
    this.map.on('mouseenter', layerId, e => this.#mouseEnterFeature(e))
    this.map.on('mouseleave', layerId, e => this.#mouseLeaveFeature(e))
  }

  #mapSelectionChanged (features) {
    features.map(f => getRowFromId(f.properties.original_id)).forEach(row => row.rowController.highlight())
  }

  #featureUpdated (feature) {
    // TODO: when it’s a linestring or a polygon, we want to wait until the editing is done
    //       and not post right away the change
    const row = getRowFromId(feature.id)
    row.rowController.update(feature.geometry)
    this.setMode(modes.DEFAULT)
  }

  #featureCreated (feature) {
    this.currentLayerController.createRow(feature.geometry)
    this.draw.delete(feature.id)
    this.setMode(modes.DEFAULT)
  }

  #setActive (feature, state) {
    this.activeFeature = feature
    this.map.setFeatureState(this.activeFeature, { state })
  }

  #unsetActive () {
    if (this.activeFeature) {
      this.map.setFeatureState(this.activeFeature, { state: 'default' })
      this.activeFeature = null
    }
  }

  #mouseEnterFeature (e) {
    this.map.getCanvas().style.cursor = 'pointer'
    this.#unsetActive()
    this.#setActive(e.features[0], 'hover')
  }

  #mouseLeaveFeature (e) {
    this.map.getCanvas().style.cursor = ''
    this.#unsetActive()
  }

  #editFeature (e) {
    if (this.mode === modes.ADD_FEATURE) {
      // When we are adding a feature, we don’t do anything and let draw handle it
      return
    }
    const features = this.map.queryRenderedFeatures(e.point, {
      layers: Object.keys(this.layers)
    })
    const drawFeature = this.draw.getFeatureIdsAt(e.point)

    if (features.length > 0 && drawFeature.length === 0) {
      const featureId = features[0].properties.original_id
      if (featureId !== this.currentFeatureId) {
        this.setMode(modes.EDIT_FEATURE, { features, featureId })

        const path = `/rows/${featureId}`
        const url = new URL(path, window.location.origin)
        // queryRenderedFeatures may split the features geometries.
        // See https://docs.mapbox.com/mapbox-gl-js/api/map/#map#queryrenderedfeatures
        // We need to fetch the full geometry before adding it to draw.
        // TODO: when it’s a point, no need to fetch the data, we have the exact coordinates in the MVT
        fetch(url)
          .then((response) => response.json())
          .then((geojson) => {
            geojson.id = featureId
            this.draw.add(geojson)
            const geometryType = this.layers[features[0].layer.id]
            if (geometryType === 'point') {
              this.draw.changeMode('simple_select', { featureIds: [featureId] })
            } else {
              this.draw.changeMode('direct_select', { featureId })
            }
          }).catch(() => this.setMode(modes.DEFAULT))
      }
    } else if (drawFeature.length === 0) {
      // We clicked on no feature, we switch back to the default mode
      this.setMode(modes.DEFAULT)
    }
  }
}

function getRowFromId (id) {
  return document.getElementById('row_' + id)
}

export default MapState
