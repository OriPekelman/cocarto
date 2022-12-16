# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "process", to: "https://ga.jspm.io/npm:@jspm/core@2.0.0-beta.27/nodelibs/browser/process-production.js"
pin "@hotwired/stimulus", to: "https://ga.jspm.io/npm:@hotwired/stimulus@3.2.1/dist/stimulus.js"
pin "@hotwired/turbo-rails", to: "https://ga.jspm.io/npm:@hotwired/turbo-rails@7.2.4/app/javascript/turbo/index.js"
pin "@hotwired/turbo", to: "https://ga.jspm.io/npm:@hotwired/turbo@7.2.4/dist/turbo.es2017-esm.js"
pin "@rails/actioncable/src", to: "https://ga.jspm.io/npm:@rails/actioncable@7.0.4/src/index.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin "maplibre-gl", to: "https://ga.jspm.io/npm:maplibre-gl@2.4.0/dist/maplibre-gl.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/channels", under: "channels"
pin_all_from "app/javascript/lib", under: "lib"
pin "@mapbox/mapbox-gl-draw", to: "https://ga.jspm.io/npm:@mapbox/mapbox-gl-draw@1.3.0/dist/mapbox-gl-draw.js"
pin "@floating-ui/dom", to: "https://cdn.skypack.dev/@floating-ui/dom?min"
pin "hotkeys-js", to: "https://ga.jspm.io/npm:hotkeys-js@3.10.1/dist/hotkeys.esm.js"
pin "@maplibre/maplibre-gl-geocoder", to: "https://ga.jspm.io/npm:@maplibre/maplibre-gl-geocoder@1.5.0/lib/index.js"
pin "events", to: "https://ga.jspm.io/npm:@jspm/core@2.0.0-beta.27/nodelibs/browser/events.js"
pin "fuzzy", to: "https://ga.jspm.io/npm:fuzzy@0.1.3/lib/fuzzy.js"
pin "lodash.debounce", to: "https://ga.jspm.io/npm:lodash.debounce@4.0.8/index.js"
pin "subtag", to: "https://ga.jspm.io/npm:subtag@0.5.0/subtag.js"
pin "suggestions-list", to: "https://ga.jspm.io/npm:suggestions-list@0.0.2/index.js"
pin "xtend", to: "https://ga.jspm.io/npm:xtend@4.0.2/immutable.js"
pin "stimulus-use", to: "https://ga.jspm.io/npm:stimulus-use@0.51.1/dist/index.js"
