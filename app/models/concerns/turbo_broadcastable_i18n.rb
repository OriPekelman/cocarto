module TurboBroadcastableI18n
  # Uses Turbo::Broadcastable to stream to *each* the app locales.
  # This is useful if the rendered fragment includes localized text.
  # Appends the current locale identifier to the streamable, e.g. `layer-1234:fr`
  # See also TurboStreamsI18nHelper.

  def broadcast_i18n_replace_to(*streamables, **opts)
    with_available_locales { |locale| broadcast_replace_to(*streamables + [locale], **opts) }
  end

  def broadcast_i18n_update_to(*streamables, **opts)
    with_available_locales { |locale| broadcast_update_to(*streamables + [locale], **opts) }
  end

  def broadcast_i18n_before_to(*streamables, **opts)
    with_available_locales { |locale| broadcast_before_to(*streamables + [locale], **opts) }
  end

  def broadcast_i18n_after_to(*streamables, target:, **rendering)
    with_available_locales { |locale| broadcast_after_to(*streamables + [locale], target: target, **rendering) }
  end

  def broadcast_i18n_append_to(*streamables, **opts)
    with_available_locales { |locale| broadcast_append_to(*streamables + [locale], **opts) }
  end

  def broadcast_i18n_prepend_to(*streamables, **opts)
    with_available_locales { |locale| broadcast_prepend_to(*streamables + [locale], **opts) }
  end

  def with_available_locales
    I18n.available_locales.each do |tmp_locale|
      I18n.with_locale(tmp_locale) do
        yield(tmp_locale)
      end
    end
  end
end
