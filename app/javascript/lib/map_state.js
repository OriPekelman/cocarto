/* global ResizeObserver */
import { newMap, geocoderApi, newGeolocateControl } from 'lib/map_helpers'
import MapboxDraw from '@mapbox/mapbox-gl-draw'
import MaplibreGeocoder from '@maplibre/maplibre-gl-geocoder'
import maplibregl from 'maplibre-gl'
import PresenceTrackers from 'lib/presence_trackers'
import onMapUpdate from 'lib/map_update_channel'
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
    onMapUpdate(mapId,
      layer => this.refresh(layer),
      deletedFeature => {
        this.draw.delete(deletedFeature)
        this.setMode(modes.DEFAULT)
      })

    this.map.on('load', e => { target.dataset.loaded = 'loaded' }) // System tests: Avoid interacting with the map before it's ready
    this.map.on('draw.create', ({ features }) => this.#featureCreated(features[0]))
    this.map.on('draw.update', ({ features }) => this.#featureUpdated(features[0]))
    this.map.on('mousemove', e => this.#mouseMove(e))
    this.map.on('mouseup', e => this.#editFeature(e))
    this.activeFeature = null
  }

  setMode (mode, args) {
    switch (mode) {
      case modes.DEFAULT:
        this.#unsetActive()
        this.draw.deleteAll()
        this.#mapSelectionChanged([])
        // When we enable the double click _during_ the double click
        // e.g. when finishing a polygon, it still triggers it
        // https://stackoverflow.com/a/29917394/202083
        setTimeout(500, () => this.map.doubleClickZoom.enable())
        this.currentFeatureId = null
        break
      case modes.EDIT_FEATURE:
        this.#unsetActive()
        this.draw.deleteAll()
        this.#mapSelectionChanged(args.features)
        this.currentFeatureId = args.featureId
        this.map.doubleClickZoom.disable()
        break
      case modes.ADD_FEATURE:
        this.draw.changeMode(this.drawMode)
        this.map.doubleClickZoom.disable()
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
    this.map.getContainer().setAttribute('map-state', mode)
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
    this.setMode(modes.HOVER_FEATURE, featureId)
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
  }

  #mouseMove (e) {
    // Notifies other screens where our cursor is
    this.trackers.mousemove(e)

    // Find all the features at the mouse positions
    const features = this.map.queryRenderedFeatures(e.point, {
      layers: Object.keys(this.layers)
    })

    // We exited a feature, we go back to default mode
    if (features.length === 0 && this.mode === modes.HOVER_FEATURE) {
      this.setMode(modes.DEFAULT)
    }

    // We entered a feature from nothing or from an other feature
    const ids = features.map(feature => feature.id)
    if (features.length >= 1) {
      // when two features overlap, we change the hover only if the current feature is not under the pointer
      const otherFeature = this.mode === modes.HOVER_FEATURE && !ids.includes(this.activeFeature.id)
      if (this.mode === modes.DEFAULT || otherFeature) {
        this.setMode(modes.HOVER_FEATURE, features[0])
      }
    }
  }

  #maplibreLayers (layerId) {
    // For each layer in cocarto, we have multiple layers in maplibre
    // When hiding/showing them, we need to work on each of them
    // Depending on each geometry type, not all extra layers are defined, so test their existence
    // See models/concerns/mvt.rb
    const layerSuffixes = ['', '--outline', '--hover']
    return layerSuffixes.map(suffix => layerId + suffix).filter(layer => this.map.getLayer(layer))
  }

  showLayer (layerId) {
    this.#maplibreLayers(layerId).forEach(layer => this.map.setLayoutProperty(layer, 'visibility', 'visible'))
  }

  hideLayer (layerId) {
    this.#maplibreLayers(layerId).forEach(layer => this.map.setLayoutProperty(layer, 'visibility', 'none'))
  }

  #mapSelectionChanged (features) {
    features.map(f => getRowFromId(f.properties.original_id)).forEach(row => row.rowController.highlight())
  }

  #featureUpdated (feature) {
    // TODO: when it’s a linestring or a polygon, we want to wait until the editing is done
    //       and not post right away the change
    this.#sendUpdate(feature)
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
        // - queryRenderedFeatures may split the features geometries (https://docs.mapbox.com/mapbox-gl-js/api/map/#map#queryrenderedfeatures)
        // - we also need to get the row author_id to know if we can edit it.
        // We need to fetch the full geometry and the author_id before switching to draw.
        this.#fetchFeature(featureId).then((geojson) => {
          this.setMode(modes.EDIT_FEATURE, { features, featureId })
          if (this.#canUpdate(geojson)) {
            this.draw.add(geojson)
            const geometryType = this.layers[features[0].layer.id]
            if (geometryType === 'point') {
              this.draw.changeMode('simple_select', { featureIds: [featureId] })
            } else {
              this.draw.changeMode('direct_select', { featureId })
            }
          }
        }).catch(() => this.setMode(modes.DEFAULT))
      }
    } else if (drawFeature.length === 0) {
      // We clicked on no feature, we switch back to the default mode
      this.setMode(modes.DEFAULT)
    }
  }

  #fetchFeature (featureId) {
    const url = new URL(`/rows/${featureId}`, window.location.origin)
    return fetch(url).then((response) => response.json())
  }

  #canUpdate (feature) {
    // Cf RowPolicy#update?, cf restricted_controller.js
    // We can’t use restricted normally since we’re not in stimulus, and it wouldn't be very practical anyway since our data comes from json.
    // Let’s just fetch the data attributes and implement the match here as well.
    const role = this.map.getContainer().closest('[data-controller~=restricted]').dataset.restrictedRoleValue
    const authorizations = ['owner', 'editor', `contributor-${feature.properties.author_id}`]
    return authorizations.some(authorization => role.startsWith(authorization))
  }

  #sendUpdate (feature) {
    const token = document.head.querySelector('meta[name="csrf-token"]').content
    const formData = new FormData()
    formData.append('row[geojson]', JSON.stringify(feature.geometry))

    const url = new URL(`/rows/${feature.id}`, window.location.origin)
    fetch(url, { method: 'PATCH', headers: { 'X-CSRF-Token': token }, body: formData }).then() // Ignore the response :shrug:
  }
}

function getRowFromId (id) {
  return document.getElementById('row_' + id)
}

export default MapState
