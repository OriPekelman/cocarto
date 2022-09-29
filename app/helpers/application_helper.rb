module ApplicationHelper
  def embedded_svg filename, options = {}
    file = File.read(Rails.root.join("app", "assets", "images", filename))
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
  def button_with_icon_delete text, filename, method, **options
    button_tag options do
      embedded_svg(filename).concat(text)
    end
  end
end
