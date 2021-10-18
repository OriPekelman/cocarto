import { Controller } from '@hotwired/stimulus'
import maplibregl from 'maplibre-gl'
import 'maplibre-gl/dist/maplibre-gl.css'
import Map from 'maplibre-gl/types/ui/map'
import LngLat from 'maplibre-gl/types/geo/lng_lat'
import Popup from 'maplibre-gl/types/ui/popup'

function popup(lngLat: LngLat) {
  const formTemplate = <HTMLTemplateElement>document.getElementById('points-form-template')
  const clone = document.importNode(formTemplate.content, true)

  return new maplibregl.Popup({anchor: 'bottom', })
  .setLngLat(lngLat)
  .setDOMContent(clone)
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
      popup(e.lngLat).addTo(this.map);
      this.longitudeDisplayTarget.innerText = e.lngLat.lng.toFixed(5);
      this.longitudeFieldTarget.value = e.lngLat.lng;
      this.latitudeDisplayTarget.innerText = e.lngLat.lat.toFixed(5);
      this.latitudeFieldTarget.value = e.lngLat.lat;
    });
  }
}
