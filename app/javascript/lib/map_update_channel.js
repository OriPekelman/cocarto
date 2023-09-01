import consumer from 'channels/consumer'

export default function onMapUpdate (mapId, callback, deletedFeature) {
  consumer.subscriptions.create({ channel: 'MapUpdateChannel', map: mapId }, {
    received (data) {
      callback(data.layer)
      if (data.deleted_feature) {
        deletedFeature(data.deleted_feature)
      }
    }
  })
}
