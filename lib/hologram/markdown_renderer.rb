module Hologram
  class MarkdownRenderer < Redcarpet::Render::HTML
    def block_code(code, language)
      if language and language.include?('example')
        if language.include?('js')
          # first actually insert the code in the docs so that it will run and make our example work.
          '<script>' + code + '</script>
          <div class="codeBlock jsExample">' + Pygments.highlight(code) + '</div>'
        else
          '<div class="codeExample">' + '<div class="exampleOutput">' + render_html(code, language) + '</div>' + '<div class="codeBlock">' + Pygments.highlight(code, :lexer => get_lexer(language)) + '</div>' + '</div>'
        end
      else
        '<div class="codeBlock">' + Pygments.highlight(code) + '</div>'
      end
    end

    private
    def render_html(code, language)
      case language
        when 'haml_example'
          safe_require('haml', language)
          return Haml::Engine.new(code.strip).render(template_rendering_scope, {})
        when 'slim_example'
          safe_require('slim', language)
          return Slim::Template.new { code.strip }.render(template_rendering_scope, {})
        else
          code
      end
    end

    def template_rendering_scope
      Object.new
    end

    def get_lexer(language)
      case language
        when 'haml_example'
          'haml'
        else
          'html'
      end
    end

    def safe_require(templating_library, language)
      begin
        require templating_library
      rescue LoadError
        raise "#{templating_library} must be present for you to use #{language}"
      end
    end
  end
end
