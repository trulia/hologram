require 'erb'

module Hologram
  class BlockCodeRenderer < Struct.new(:code, :markdown_language)
    def render
      if is_html? || is_haml? || is_slim?
        if is_table?
          if is_html?
            examples = code.split("\n\n").map { |code_snippit| HtmlExample.new(code_snippit) }
          elsif is_haml?
            examples = code.split("\n\n").map { |code_snippit| HamlExample.new(code_snippit) }
          elsif is_slim?
            examples = code.split("\n\n").map { |code_snippit| SlimExample.new(code_snippit) }
          end
          ERB.new(code_table_template).result(binding)
        else
          if is_html?
            example = HtmlExample.new(code)
          elsif is_haml?
            example = HamlExample.new(code)
          elsif is_slim?
            example = SlimExample.new(code)
          end
          ERB.new(code_example_template).result(example.get_binding)
        end

      elsif is_js?
        example = JsExample.new(code)
        ERB.new(js_example_template).result(example.get_binding)

      elsif is_jsx?
        example = JsxExample.new(code)
        ERB.new(jsx_example_template).result(example.get_binding)

      else
        example = Example.new(code)
        ERB.new(unknown_example_template).result(example.get_binding)
      end
    end

    private

    def code_example_template
      [
        "<div class=\"codeExample\">",
          "<div class=\"exampleOutput\">",
            "<%= rendered_example %>",
          "</div>",
          "<div class=\"codeBlock\">",
            "<div class=\"highlight\">",
              "<pre>",
                "<%= code_example %>",
              "</pre>",
            "</div>",
          "</div>",
        "</div>"
      ].join('')
    end

    def code_table_template
      [
        "<div class=\"codeTable\">",
          "<table>",
            "<tbody>",
              "<% examples.each do |example| %>",
                "<tr>",
                  "<th>",
                    "<div class=\"exampleOutput\">",
                      "<%= example.rendered_example %>",
                    "</div>",
                  "</th>",
                  "<td>",
                    "<div class=\"codeBlock\">",
                      "<div class=\"highlight\">",
                        "<pre>",
                          "<%= example.code_example %>",
                        "</pre>",
                      "</div>",
                    "</div>",
                  "</td>",
                "</tr>",
              "<% end %>",
            "</tbody>",
          "</table>",
        "</div>",
      ].join('')
    end

    def js_example_template
      [
        "<script><%= rendered_example %></script> ",
        "<div class=\"codeBlock jsExample\">",
          "<div class=\"highlight\">",
            "<pre>",
              "<%= code_example %>",
            "</pre>",
          "</div>",
        "</div>",
      ].join('')
    end

    def jsx_example_template
      [
        "<script type='text/jsx'><%= rendered_example %></script> ",
        "<div class=\"codeBlock jsExample\">",
          "<div class=\"highlight\">",
            "<pre>",
              "<%= code_example %>",
            "</pre>",
          "</div>",
        "</div>",
      ].join('')
    end

    def unknown_example_template
      [
        "<div class=\"codeBlock\">",
          "<div class=\"highlight\">",
            "<pre>",
              "<%= code_example %>",
            "</pre>",
          "</div>",
        "</div>",
      ].join('')
    end

    def is_haml?
      markdown_language && markdown_language.include?('haml_example')
    end

    def is_html?
      markdown_language && markdown_language.include?('html_example')
    end

    def is_slim?
      markdown_language && markdown_language.include?('slim_example')
    end

    def is_js?
      markdown_language && markdown_language == 'js_example'
    end

    def is_jsx?
      markdown_language && markdown_language == 'jsx_example'
    end

    def is_table?
      markdown_language && markdown_language.include?('example_table')
    end
  end


  class Example < Struct.new(:code)
    def rendered_example
      code
    end

    def code_example
      formatter.format(lexer.lex(code))
    end

    def get_binding
      binding
    end

    private

    def formatter
      @_formatter ||= Rouge::Formatters::HTML.new(wrap: false)
    end

    def lexer
      @_lexer ||= Rouge::Lexer.find_fancy('guess', code)
    end

    def safe_require(templating_library, language)
      begin
        require templating_library
      rescue LoadError
        raise "#{templating_library} must be present for you to use #{language}"
      end
    end
  end

  class HtmlExample < Example
    private

    def lexer
      @_lexer ||= Rouge::Lexer.find('html')
    end
  end

  class HamlExample < Example
    def rendered_example
      haml_engine.render(Object.new, {})
    end

    private

    def haml_engine
      safe_require 'haml', 'haml'
      Haml::Engine.new(code.strip)
    end

    def slim_engine(code_snippet)
      safe_require 'slim', markdown_language
      Slim::Template.new { code_snippet.strip }
    end

    def lexer
      @_lexer ||= Rouge::Lexer.find('haml')
    end
  end

  class SlimExample < Example
    def rendered_example
      slim_engine.render(Object.new, {})
    end

    private

    def slim_engine
      safe_require 'slim', 'slim'
      Slim::Template.new { code.strip }
    end

    def lexer
      @_lexer ||= Rouge::Lexer.find('slim')
    end
  end

  class JsExample < Example
    private

    def lexer
      @_lexer ||= Rouge::Lexer.find('js')
    end
  end

  class JsxExample < Example
    private

    def lexer
      @_lexer ||= Rouge::Lexer.find('html')
    end
  end
end
