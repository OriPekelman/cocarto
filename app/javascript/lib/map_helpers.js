import maplibre from 'maplibre-gl'

function newMap (node, center, zoom) {
  return new maplibre.Map({
    container: node,
    style:
      'https://api.maptiler.com/maps/74282552-6648-4800-9768-d62dac64839e/style.json?key=rF1iMNeNc3Eh3ES7Ke8H',
    center,
    zoom,
    preserveDrawingBuffer: true, // allows you to export an image
    attributionControl: false
  }).addControl(new maplibre.AttributionControl({
    customAttribution: '<a href="https://www.maptiler.com/copyright/" target="_blank">&copy; MapTiler</a> <a href="https://www.openstreetmap.org/copyright" target="_blank">&copy; OpenStreetMap contributors</a>',
    compact: false
  })).addControl(new maplibre.NavigationControl({
    showCompass: false
  })).addControl(new maplibre.ScaleControl())
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

// Points, line strings and polygons are styled following
// https://maplibre.org/maplibre-gl-js-docs/style-spec
// This function returns the styles for the features (not the basemap)
const pointStyles = [
  {
    id: 'highlight-active-points',
    type: 'circle',
    filter: ['all',
      ['==', '$type', 'Point'],
      ['==', 'meta', 'feature'],
      ['==', 'active', 'true']],
    paint: {
      'circle-radius': 10,
      'circle-color': '#fff'
    }
  },
  {
    id: 'points-base',
    type: 'circle',
    filter: ['all',
      ['==', '$type', 'Point'],
      ['==', 'meta', 'feature']],
    paint: {
      'circle-radius': 6,
      'circle-color': ['get', 'user_marker-color']
    }
  },
  {
    id: 'points-outline',
    type: 'circle',
    filter: ['all', ['==', '$type', 'Point'], ['==', 'meta', 'feature']],
    paint: {
      'circle-radius': 4,
      'circle-stroke-color': '#fff',
      'circle-stroke-width': 1,
      'circle-opacity': 0
    }
  }
]

const lineStyles = [
    // line stroke
    {
      id: 'gl-draw-line',
      type: 'line',
      filter: ['all', ['==', '$type', 'LineString'], ['!=', 'mode', 'static']],
      layout: {
        'line-cap': 'round',
        'line-join': 'round'
      },
      paint: {
        'line-color': ['coalesce', ['get', 'user_stroke'], '#555'],
        'line-width': ['coalesce', ['get', 'user_stroke-width'], 2]
      }
    }
]

const polygonStyles = [
  {
    id: 'gl-draw-polygon-fill',
    type: 'fill',
    filter: ['all', ['==', '$type', 'Polygon'], ['!=', 'mode', 'static']],
    paint: {
      'fill-color': ['coalesce', ['get', 'user_fill'], '#555'],
      'fill-outline-color': ['coalesce', ['get', 'user_outline-color'], '#555'],
      'fill-opacity': 0.1
    }
  },
  // polygon mid points
  {
    id: 'gl-draw-polygon-midpoint',
    type: 'circle',
    filter: ['all',
      ['==', '$type', 'Point'],
      ['==', 'meta', 'midpoint']],
    paint: {
      'circle-radius': 3,
      'circle-color': ['coalesce', ['get', 'user_stroke'], '#555']
    }
  },
  // polygon outline stroke
  // This doesn't style the first edge of the polygon, which uses the line stroke styling instead
  {
    id: 'gl-draw-polygon-stroke-active',
    type: 'line',
    filter: ['all', ['==', '$type', 'Polygon'], ['!=', 'mode', 'static']],
    layout: {
      'line-cap': 'round',
      'line-join': 'round'
    },
    paint: {
      'line-color': ['coalesce', ['get', 'user_stroke'], '#555'],
      'line-width': ['coalesce', ['get', 'user_stroke-width'], 2]
    }
  },
]

// When editing lines and polygons, vertices are hilighted
const vertexStyles = [
    // vertex point halos
    {
      id: 'gl-draw-polygon-and-line-vertex-halo-active',
      type: 'circle',
      filter: ['all', ['==', 'meta', 'vertex'], ['==', '$type', 'Point'], ['!=', 'mode', 'static']],
      paint: {
        'circle-radius': 5,
        'circle-color': '#FFF'
      }
    },
    // vertex points
    {
      id: 'gl-draw-polygon-and-line-vertex-active',
      type: 'circle',
      filter: ['all', ['==', 'meta', 'vertex'], ['==', '$type', 'Point'], ['!=', 'mode', 'static']],
      paint: {
        'circle-radius': 3,
        'circle-color': ['coalesce', ['get', 'user_stroke'], '#555'],
      }
    },
]

const drawStyles = [pointStyles, lineStyles, polygonStyles, vertexStyles].flat()

export { newMap, drawStyles, geocoderApi }
