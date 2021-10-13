console.log("Starting ĝis")

import "@hotwired/turbo-rails"
import "../controllers"
import * as ActiveStorage from "@rails/activestorage"

ActiveStorage.start()

// Example: Import a stylesheet in app/frontend/index.css
// import '~/index.css'
