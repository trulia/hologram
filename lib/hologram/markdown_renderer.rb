require 'hologram/block_code_renderer'

include ERB::Util

module Hologram
  class MarkdownRenderer < Redcarpet::Render::HTML
    def list(contents, list_type)
      case list_type
      when :ordered
        "<ol class=\"#{css_class_name}\">#{contents}</ol>"
      else
        "<ul class=\"#{css_class_name}\">#{contents}</ul>"
      end
    end

    def paragraph(text)
      "<p class=\"#{css_class_name}\">#{text}</p>"
    end

    def table(header, body)
      "<table class=\"#{css_class_name}\"> #{header} #{body} </table>"
    end

    def codespan(code)
      "<code class=\"#{css_class_name}\">#{html_escape(code)}</code>"
    end

    def link(link, title, content)
      "<a class=\"#{css_class_name}\" href=\"#{link}\" title=\"#{title || link}\">#{content}</a>"
    end

    def block_code(code, language)
      BlockCodeRenderer.new(code, language).render
    end

    def postprocess(full_document)
      invalid_links = full_document.scan(/(?: \[ [\s\w]+ \]){2}/x)

      invalid_links.each do |invalid_link|
        component = /\[.+\]/.match(invalid_link)[1]
        DisplayMessage.warning("Invalid reference link - #{invalid_link}." +
                               "Presumably the component #{component} does not exist.")
      end

      full_document
    end

    def css_class_name
      'styleguide'
    end
  end
end
