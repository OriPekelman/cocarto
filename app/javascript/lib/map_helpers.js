import maplibre from 'maplibre-gl'

function newMap (node) {
  return new maplibre.Map({
    container: node,
    style:
      'https://api.maptiler.com/maps/basic/style.json?key=rF1iMNeNc3Eh3ES7Ke8H',
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

function newMarker (lngLat) {
  const marker = new maplibre.Marker({ draggable: true })
  marker.setLngLat(lngLat)
  return marker
}

export { newMap, newMarker }
