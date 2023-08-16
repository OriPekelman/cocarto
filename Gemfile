source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails"
# Use postgresql as the database for Active Record
gem "pg"
gem "activerecord-postgres_enum"
gem "activerecord-postgis-adapter"
gem "rgeo-geojson"
# Use Puma as the app server
gem "puma"
gem "pundit"
gem "propshaft"
gem "dartsass-rails"
gem "turbo-rails"
gem "hotwire-rails"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder"
# Use Redis adapter to run Action Cable in production
gem "redis"
# Use GoodJob for ActiveJob
gem "good_job"
# Use Active Model has_secure_password
# gem "bcrypt"
gem "importmap-rails"
# Use Active Storage variant
gem "aws-sdk-s3"
# gem "image_processing"
gem "rubyzip"
# Used for authentification
gem "devise"
gem "devise_invitable"
# i18n
gem "http_accept_language"
gem "rails-i18n"
gem "cache_with_locale"
# rails additions
gem "premailer-rails"
gem "view_component"
gem "view_component-fragment_caching"
gem "active_link_to"
gem "turbo_flash"
gem "ranked-model"

gem "roo"
gem "roo-xls"

# perfs and errors
gem "sentry-ruby"
gem "sentry-rails"
gem "stackprof"

gem "foreman"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

group :development, :test do
  # Call "byebug" anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "localhost" # use https in development
  gem "standard"
  gem "rubocop-rails", require: false
  gem "rubocop-minitest", require: false
  gem "i18n-tasks" # Verifies that we have all translations
  gem "erb_lint", require: false
  gem "dotenv-rails"
end

group :development do
  # Access an interactive console on exception pages or by calling "console" anywhere in the code.
  gem "web-console"
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem "rack-mini-profiler"
  gem "listen"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
  gem "annotate"
  gem "rails-erd"
  gem "active_record_doctor"
  gem "letter_opener_web"
  gem "rails_real_favicon"
  gem "thor"
end

group :test do
  # Cuprite is used for system tests (to pilot chrome driver)
  gem "cuprite"
  gem "minitest-reporters"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
