/* global ResizeObserver */
import { newMap, geocoderApi, newGeolocateControl } from 'lib/map_helpers'
import MapboxDraw from '@mapbox/mapbox-gl-draw'
import MaplibreGeocoder from '@maplibre/maplibre-gl-geocoder'
import maplibregl from 'maplibre-gl'
import PresenceTrackers from 'lib/presence_trackers'

class MapState {
  constructor ({ target, mapId, lng, lat, zoom, leftToolbar, rightToolbar, style }) {
    this.map = newMap(target, [lng, lat], zoom, style)

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
    this.map.on('draw.selectionchange', e => this.#mapSelectionChanged(e))
    this.map.on('draw.create', ({ features }) => this.#featureCreated(features[0]))
    this.map.on('draw.update', ({ features }) => this.#featureUpdated(features[0]))
    this.map.on('mousemove', e => this.trackers.mousemove(e))

    this.hoveredFeature = null
  }

  getMap () {
    return this.map
  }

  getDraw () {
    return this.draw
  }

  getDrawMode () {
    return this.drawMode
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

  registerLayer (layerId) {
    this.map.on('mouseenter', layerId, e => this.#mouseEnterFeature(e))
    this.map.on('mouseleave', layerId, e => this.#mouseLeaveFeature(e))
  }

  #mapSelectionChanged ({ features }) {
    features.map(getRowFromFeature).forEach(row => row.rowController.highlight())
  }

  #featureUpdated (feature) {
    const row = getRowFromFeature(feature)
    row.rowController.update(feature.geometry)
  }

  #featureCreated (feature) {
    this.currentLayerController.createRow(feature.geometry)
    // When we submit the drawn row, we get one back from the server through turbo
    // So we remove the one we’ve just drawn
    // Later we’ll be smarter to avoid destruction and recreation
    this.draw.delete(feature.id)
  }

  #mouseEnterFeature (e) {
    this.map.getCanvas().style.cursor = 'pointer'
    if (this.hoveredFeature) {
      this.map.setFeatureState(this.hoveredFeature, { hover: false })
    }
    this.hoveredFeature = e.features[0]
    this.map.setFeatureState(this.hoveredFeature, { hover: true })
  }

  #mouseLeaveFeature (e, layerId) {
    this.map.getCanvas().style.cursor = ''
    if (this.hoveredFeature) {
      this.map.setFeatureState(this.hoveredFeature, { hover: false })
      this.hoveredFeature = null
    }
  }
}

function getRowFromFeature (feature) {
  return document.getElementById(feature.id)
}

export default MapState
