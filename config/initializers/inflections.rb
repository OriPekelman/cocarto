# Be sure to restart your server when you modify this file.

ActiveSupport::Inflector.inflections do |inflect|
  inflect.acronym "CSV"
  inflect.acronym "WFS"
end

# Specific rules for zeitwerk autoloading in Development
# See https://guides.rubyonrails.org/autoloading_and_reloading_constants.html#customizing-inflections
Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "geojson" => "GeoJSON"
  )
end
