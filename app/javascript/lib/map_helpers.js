import maplibre from 'maplibre-gl'

function newMap (node) {
  return new maplibre.Map({
    container: node,
    style:
      'https://api.maptiler.com/maps/74282552-6648-4800-9768-d62dac64839e/style.json?key=rF1iMNeNc3Eh3ES7Ke8H',
    center: [0, 0],
    zoom: 1,
    attributionControl: false
  }).addControl(new maplibre.AttributionControl({
    customAttribution: '<a href="https://www.maptiler.com/copyright/" target="_blank">&copy; MapTiler</a> <a href="https://www.openstreetmap.org/copyright" target="_blank">&copy; OpenStreetMap contributors</a>',
    compact: false
  })).addControl(new maplibre.NavigationControl({
    showCompass: false
  })).addControl(new maplibre.ScaleControl())
}

// Points, line strings and polygons are styled following
// https://maplibre.org/maplibre-gl-js-docs/style-spec
// This function returns the styles for the features (not the basemap)
function maplibreGLFeaturesStyle (color) {
  return [
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
        'circle-color': ['coalesce', ['get', 'user_color'], color]
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
    },
    {
      id: 'gl-draw-polygon-fill',
      type: 'fill',
      filter: ['all', ['==', '$type', 'Polygon'], ['!=', 'mode', 'static']],
      paint: {
        'fill-color': ['coalesce', ['get', 'user_fill'], color],
        'fill-outline-color': ['coalesce', ['get', 'user_outline-color'], color],
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
        'circle-color': ['coalesce', ['get', 'user_color'], color]
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
        'line-color': ['coalesce', ['get', 'user_stroke'], color],
        'line-width': ['coalesce', ['get', 'user_stroke-width'], 2]
      }
    },
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
        'circle-color': ['coalesce', ['get', 'user_color'], color]
      }
    },
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
        'line-color': ['coalesce', ['get', 'user_stroke'], color],
        'line-width': ['coalesce', ['get', 'user_stroke-width'], 2]
      }
    }
  ]
}

export { newMap, maplibreGLFeaturesStyle }
