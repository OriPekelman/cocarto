import { Controller } from '@hotwired/stimulus'
import maplibregl from 'maplibre-gl'
import 'maplibre-gl/dist/maplibre-gl.css'
import Maplibre from 'maplibre-gl/types/ui/map'
import LngLat from 'maplibre-gl/types/geo/lng_lat'
import Popup from 'maplibre-gl/types/ui/popup'
import Marker from 'maplibre-gl/types/ui/marker'

function popup(lngLat: LngLat) : Popup {
  const formTemplate = <HTMLTemplateElement>document.getElementById('points-form-template')
  const clone = document.importNode(formTemplate.content, true)

  return new maplibregl.Popup({anchor: 'bottom', })
  .setLngLat(lngLat)
  .setDOMContent(clone)
  .setMaxWidth("300px");
}

function marker(point: HTMLElement): Marker {
  const lng = +point.getAttribute('data-lng');
  const lat = +point.getAttribute('data-lat');

  return new maplibregl.Marker().setLngLat({lng, lat});
}

class MapBaseController extends Controller {
  public longitudeDisplayTarget!: HTMLInputElement;
  public longitudeFieldTarget!: HTMLInputElement;
  public latitudeDisplayTarget!: HTMLInputElement;
  public latitudeFieldTarget!: HTMLInputElement;
  public mapTarget!: HTMLInputElement;
}

export default class extends (Controller  as typeof MapBaseController) {
  static targets = [ "longitudeDisplay", "longitudeField", "latitudeDisplay", "latitudeField", "map", "point" ]
  map: Maplibre
  markers: Map<string, Marker>

  initialize() {
    this.markers = new Map();
  }

  connect() {
    this.map = new maplibregl.Map({
      container: this.mapTarget.id,
      style:
        'https://api.maptiler.com/maps/basic/style.json?key=rF1iMNeNc3Eh3ES7Ke8H',
      center: [0, 0],
      zoom: 1,
    })

    this.markers.forEach(marker => marker.addTo(this.map));

    this.map.on('click', e => {
      popup(e.lngLat).addTo(this.map);
      this.longitudeDisplayTarget.innerText = e.lngLat.lng.toFixed(5);
      this.longitudeFieldTarget.value = e.lngLat.lng;
      this.latitudeDisplayTarget.innerText = e.lngLat.lat.toFixed(5);
      this.latitudeFieldTarget.value = e.lngLat.lat;
    });
  }

  pointTargetConnected(point: HTMLElement) {
    const id = point.getAttribute('id');
    const m = marker(point);
    this.markers.set(id, m);
    if(this.map) {
      m.addTo(this.map)
    }
  }

  pointTargetDisconnected(point: HTMLElement) {
    const id = point.getAttribute('id');
    const m = this.markers.get(id);
    m.remove();
    this.markers.delete(id);
  }
}
