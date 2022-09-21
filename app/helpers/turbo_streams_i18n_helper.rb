module TurboStreamsI18nHelper
  # Same as Turbo::StreamsHelper#turbo_stream_from, specifying the current locale to stream from.
  # See also TurboBroadcastableI18n
  def turbo_stream_i18n_from(*streamables, **attributes)
    turbo_stream_from(*streamables + [I18n.locale], **attributes)
  end
end
