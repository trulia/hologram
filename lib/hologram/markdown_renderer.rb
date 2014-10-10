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

    def css_class_name
      'styleguide'
    end
  end
end
