import consumer from 'channels/consumer'

export default function onMapUpdate (mapId, callback) {
  consumer.subscriptions.create({ channel: 'MapUpdateChannel', map: mapId }, {
    received (data) {
      callback(data.layer)
    }
  })
}
