module ApplicationHelper
  # Embeds the svg file directly in the dom
  # This allows to use `currentColor` attribute and style the file with CSS
  # Currently accepted options that are passed to the <svg> tag:
  # - class
  # - style
  def embedded_svg(filename, **options)
    file = Rails.root.join("app", "assets", "images", filename).read
    doc = Nokogiri::HTML::DocumentFragment.parse file
    svg = doc.at_css "svg"
    svg["class"] = options[:class] if options[:class].present?
    svg["style"] = options[:style] if options[:style].present?

    doc.to_html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def link_with_icon text, path, filename, **options
    link_to path, options do
      embedded_svg(filename).concat(text)
    end
  end

  def button_with_icon text, filename, **options
    button_tag options do
      embedded_svg(filename).concat(text)
    end
  end

  def updated_at_tag(record, author = nil)
    return if record.nil?

    text = if author.present?
      t("common.updated_at_by", date: time_ago_in_words(record.updated_at), user: author.display_name)
    else
      t("common.updated_at", date: time_ago_in_words(record.updated_at))
    end
    tag.span title: l(record.updated_at, format: :long) do
      "- " + text
    end
  end
end
