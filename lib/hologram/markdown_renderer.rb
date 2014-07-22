module Hologram
  class MarkdownRenderer < Redcarpet::Render::HTML
    def block_code(code, language)
      formatter = Rouge::Formatters::HTML.new(wrap: false)
      if language and language.include?('example')
        if language.include?('js')
          lexer = Rouge::Lexer.find('js')
          # first actually insert the code in the docs so that it will run and make our example work.
          '<script>' + code + '</script> <div class="codeBlock jsExample"><div class="highlight"><pre>' + formatter.format(lexer.lex(code)) + '</pre></div></div>'
        else
          lexer = Rouge::Lexer.find(get_lexer(language))
          '<div class="codeExample">' + '<div class="exampleOutput">' + render_html(code, language) + '</div>' + '<div class="codeBlock"><div class="highlight"><pre>' + formatter.format(lexer.lex(code)) + '</pre></div></div>' + '</div>'
        end
      else
        lexer = Rouge::Lexer.find_fancy('guess', code)
        '<div class="codeBlock"><div class="highlight"><pre>' + formatter.format(lexer.lex(code)) + '</pre></div></div>'
      end
    end

    private
    def render_html(code, language)
      case language
        when 'haml_example'
          safe_require('haml', language)
          return Haml::Engine.new(code.strip).render(template_rendering_scope, {})
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
