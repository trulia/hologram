module Hologram
  class BlockCodeRenderer < Struct.new(:code, :markdown_language)
    def render
      if is_html? || is_haml?
        if is_table?
          [
            "<div class=\"codeTable\">",
              "<table>",
                "<tbody>",
                  code_example_rows,
                "</tbody>",
              "</table>",
            "</div>",
          ].join('')
        else
          [
            "<div class=\"codeExample\">",
              example_output(code),
              code_block(code),
            "</div>"
          ].join('')
        end

      elsif is_js?
        [
          "<script>#{code}</script> ",
          code_block(code, extra_classes: ['jsExample'])
        ].join('')

      else
        code_block(code)
      end
    end

    private

    def is_haml?
      markdown_language && markdown_language.include?('haml_example')
    end

    def is_html?
      markdown_language && markdown_language.include?('html_example')
    end

    def is_js?
      markdown_language && markdown_language == 'js_example'
    end

    def is_table?
      markdown_language && markdown_language.include?('example_table')
    end

    def example_output(code_snippet)
      [
        "<div class=\"exampleOutput\">",
          rendered_code_snippet(code_snippet),
        "</div>",
      ].join('')
    end

    def rendered_code_snippet(code_snippet)
      if is_haml?
        haml_engine(code_snippet).render(Object.new, {})
      else
        code_snippet
      end
    end

    def code_block(code_snippet, opts={})
      extra_classes = opts[:extra_classes] || []
      classes = extra_classes.insert(0, 'codeBlock')
      [
        "<div class=\"#{classes.join(' ')}\">",
          "<div class=\"highlight\">",
            "<pre>",
              "#{formatter.format(lexer.lex(code_snippet))}",
            "</pre>",
          "</div>",
        "</div>",
      ].join('')
    end

    def code_example_rows
      rows = code.split("\n\n")
      rows.inject("") do |res, row|
        res + code_example_row(row)
      end
    end

    def code_example_row(code_snippet)
      [
        "<tr>",
          "<th>",
            example_output(code_snippet),
          "</th>",
          "<td>",
            code_block(code_snippet),
          "</td>",
        "</tr>",
      ].join('')
    end

    def haml_engine(code_snippet)
      safe_require 'haml', markdown_language
      Haml::Engine.new(code_snippet.strip)
    end

    def lexer
      @_lexer ||= if is_html?
        Rouge::Lexer.find('html')
      elsif is_haml?
        Rouge::Lexer.find('haml')
      elsif is_js?
        Rouge::Lexer.find('js')
      else
        Rouge::Lexer.find_fancy('guess', code)
      end
    end

    def formatter
      @_formatter ||= Rouge::Formatters::HTML.new(wrap: false)
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