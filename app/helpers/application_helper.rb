module ApplicationHelper
  def embedded_svg filename, options = {}
    file = Rails.root.join("app", "assets", "images", filename).read
    doc = Nokogiri::HTML::DocumentFragment.parse file
    svg = doc.at_css "svg"
    if options[:class].present?
      svg["class"] = options[:class]
    end
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

    if author.present?
      "- " + t("common.updated_at_by", date: l(record.updated_at, format: :long), user: author.display_name)
    else
      "- " + t("common.updated_at", date: l(record.updated_at, format: :long))
    end
  end
end
