import maplibre from 'maplibre-gl'

function newMap (node, center, zoom, style) {
  return new maplibre.Map({
    container: node,
    style,
    center,
    zoom,
    preserveDrawingBuffer: true, // allows you to export an image
    attributionControl: false
  }).addControl(new maplibre.AttributionControl({
    customAttribution: '<a href="https://www.maptiler.com/copyright/" target="_blank">&copy; MapTiler</a> <a href="https://www.openstreetmap.org/copyright" target="_blank">&copy; OpenStreetMap contributors</a>',
    compact: false
  }))
    .addControl(new maplibre.ScaleControl())
}

function newGeolocateControl () {
  return new maplibre.GeolocateControl({
    positionOptions: {
      enableHighAccuracy: true
    },
    trackUserLocation: true
  })
}

const geocoderApi = {
  forwardGeocode: async (config) => {
    const features = []
    try {
      const request =
'https://nominatim.openstreetmap.org/search?q=' +
config.query +
'&format=geojson&polygon_geojson=1&addressdetails=1'
      const response = await fetch(request)
      const geojson = await response.json()
      for (const feature of geojson.features) {
        const center = [
          feature.bbox[0] +
(feature.bbox[2] - feature.bbox[0]) / 2,
          feature.bbox[1] +
(feature.bbox[3] - feature.bbox[1]) / 2
        ]
        const point = {
          type: 'Feature',
          geometry: {
            type: 'Point',
            coordinates: center
          },
          place_name: feature.properties.display_name,
          properties: feature.properties,
          text: feature.properties.display_name,
          place_type: ['place'],
          center
        }
        features.push(point)
      }
    } catch (e) {
      console.error(`Failed to forwardGeocode with error: ${e}`)
    }

    return {
      features
    }
  }
}

export { newMap, geocoderApi, newGeolocateControl }
