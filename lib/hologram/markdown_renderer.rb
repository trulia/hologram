require 'hologram/block_code_renderer'

include ERB::Util

module Hologram
  class MarkdownRenderer < Redcarpet::Render::HTML
    def initialize(opts={})
      super(opts)
      @link_helper = opts[:link_helper]
    end

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

    def preprocess(full_document)
      if link_helper
        link_defs + "\n" + full_document
      else
        full_document
      end
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

    private

    attr_reader :link_helper

    def link_defs
      @_link_defs ||= link_helper.all_links.map { |c_name, link| "[#{c_name}]: #{link}" }.join("\n")
    end
  end
end
