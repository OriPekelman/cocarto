import { Controller } from '@hotwired/stimulus'
import maplibregl from 'maplibre-gl'
import 'maplibre-gl/dist/maplibre-gl.css'
import Map from 'maplibre-gl/types/ui/map'
import LngLat from 'maplibre-gl/types/geo/lng_lat'

function popup(lngLat: LngLat) {
  const form = window.document.getElementById('points-form')
  form.classList.remove("hidden");

  return new maplibregl.Popup({anchor: 'bottom', closeButton: false })
  .setLngLat(lngLat)
  .setDOMContent(form)
  .setMaxWidth("300px");
}

class MapBaseController extends Controller {
  public longitudeDisplayTarget!: HTMLInputElement;
  public longitudeFieldTarget!: HTMLInputElement;
  public latitudeDisplayTarget!: HTMLInputElement;
  public latitudeFieldTarget!: HTMLInputElement;
}

export default class extends (Controller  as typeof MapBaseController) {
  static targets = [ "longitudeDisplay", "longitudeField", "latitudeDisplay", "latitudeField" ]
  map: Map

  connect() {
    this.map = new maplibregl.Map({
      container: this.element.id,
      style:
        'https://api.maptiler.com/maps/basic/style.json?key=rF1iMNeNc3Eh3ES7Ke8H',
      center: [0, 0],
      zoom: 1,
    })

    this.map.on('click', e => {
      this.longitudeDisplayTarget.innerText = e.lngLat.lng.toFixed(5);
      this.longitudeFieldTarget.value = e.lngLat.lng;
      this.latitudeDisplayTarget.innerText = e.lngLat.lat.toFixed(5);
      this.latitudeFieldTarget.value = e.lngLat.lat;
      popup(e.lngLat).addTo(this.map);
    });
  }
}
