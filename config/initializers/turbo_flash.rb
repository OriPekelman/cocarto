TurboFlash.config do |config|
  # make all flashes TurboFlash-flashes
  # config.inherit_flashes = true

  # clear the TurboFlash target if there are no flashes in a TurboStream response
  # config.clear_target_unless_flashed = true

  # the default TurboStream target element ID
  # config.target = "flash"

  # the default TurboStream action
  # config.action = :update

  # the default TurboStream partial
  config.partial = "application/flash"

  # the default flash key variable name
  # config.key = :role

  # the default flash message variable name
  # config.value = :message
end
