/* global ResizeObserver */
import { newMap, geocoderApi, newGeolocateControl } from 'lib/map_helpers'
import MapboxDraw from '@mapbox/mapbox-gl-draw'
import MaplibreGeocoder from '@maplibre/maplibre-gl-geocoder'
import maplibregl from 'maplibre-gl'
import PresenceTrackers from 'lib/presence_trackers'

class MapState {
  constructor ({ target, mapId, lng, lat, zoom, leftToolbar, rightToolbar, style }) {
    this.map = newMap(target, [lng, lat], zoom, style)
    this.layers = {}
    this.mode = 'default'
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
    this.map.on('click', e => this.#editFeature(e))
    this.activeFeature = null
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
    this.map.setStyle(this.style, {diff: true})
    this.layers[layerId] = geometryType
    this.map.on('mouseenter', layerId, e => this.#mouseEnterFeature(e))
    this.map.on('mouseleave', layerId, e => this.#mouseLeaveFeature(e))
  }

  addFeatureMode () {
    if (this.mode === 'default') {
      this.mode = 'adding'
      this.draw.changeMode(this.drawMode)
    }
  }

  setDefaultMode () {
    this.mode == 'default'
    this.draw.changeMode('simple_select')
    this.draw.deleteAll()
  }

  #mapSelectionChanged (features) {
    features.map(f => getRowFromId(f.properties.original_id)).forEach(row => row.rowController.highlight())
  }

  #featureUpdated (feature) {
    const row = getRowFromId(feature.id)
    row.rowController.update(feature.geometry)
  }

  #featureCreated (feature) {
    this.currentLayerController.createRow(feature.geometry)
    this.draw.delete(feature.id)
    this.mode = 'default'
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
    const features = this.map.queryRenderedFeatures(e.point, {
      layers: Object.keys(this.layers)
    });
    if (this.mode !== 'adding') {
      this.draw.deleteAll()
    }
    if (features.length > 0) {
      this.#mapSelectionChanged(features)
      const feature = features[0]

      const feature_id = feature.properties.original_id
      const path = `/rows/${feature_id}`
      const url = new URL(path, window.location.origin)
      fetch(url)
        .then( (response) => response.json())
        .then((geojson) => {
          geojson.id = feature_id
          const res = this.draw.add(geojson)
          const geometryType = this.layers[feature.layer.id]
          if(geometryType === "point"){
            this.draw.changeMode('simple_select', {features: [feature_id]})
          } else {
            this.draw.changeMode('direct_select', {featureId: feature_id})
          }
        })
    }
  }
}

function getRowFromId (id) {
  return document.getElementById('row_' + id)
}

export default MapState
