# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "process", to: "https://ga.jspm.io/npm:@jspm/core@2.0.0-beta.13/nodelibs/browser/process-production.js"
pin "@hotwired/stimulus", to: "https://ga.jspm.io/npm:@hotwired/stimulus@3.0.1/dist/stimulus.js"
pin "@hotwired/turbo-rails", to: "https://ga.jspm.io/npm:@hotwired/turbo-rails@7.1.0/app/javascript/turbo/index.js"
pin "@hotwired/turbo", to: "https://ga.jspm.io/npm:@hotwired/turbo@7.1.0/dist/turbo.es2017-esm.js"
pin "@rails/actioncable/src", to: "https://ga.jspm.io/npm:@rails/actioncable@6.1.4/src/index.js"
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin "maplibre-gl", to: "https://ga.jspm.io/npm:maplibre-gl@2.0.0-pre.6/dist/maplibre-gl.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/channels", under: "channels"
pin_all_from "app/javascript/lib", under: "lib"
pin "@rails/actioncable", to: "https://ga.jspm.io/npm:@rails/actioncable@7.0.0/app/assets/javascripts/actioncable.esm.js"
pin "@mapbox/mapbox-gl-draw", to: "https://ga.jspm.io/npm:@mapbox/mapbox-gl-draw@1.3.0/dist/mapbox-gl-draw.js"
