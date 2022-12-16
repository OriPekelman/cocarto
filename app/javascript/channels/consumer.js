// Reuse the hotwired/turbo stream websocket for all the action cable subscriptions.

import { cable } from '@hotwired/turbo-rails'

export default await cable.getConsumer()
