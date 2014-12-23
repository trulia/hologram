require 'erb'

module Hologram
  class BlockCodeRenderer
    def initialize(code, markdown_language, opts={})
      @code = code
      @markdown_language = markdown_language
      @path_to_custom_example_templates = opts[:path_to_custom_example_templates]
    end

    def render
      if is_html? || is_haml? || is_slim?
        if is_table?
          if is_html?
            examples = code.split("\n\n").map { |code_snippit| CodeExampleRenderers::HtmlExample.new(code_snippit) }
          elsif is_haml?
            examples = code.split("\n\n").map { |code_snippit| CodeExampleRenderers::HamlExample.new(code_snippit) }
          elsif is_slim?
            examples = code.split("\n\n").map { |code_snippit| CodeExampleRenderers::SlimExample.new(code_snippit) }
          end
          ERB.new(markup_table_template).result(binding)
        else
          if is_html?
            example = CodeExampleRenderers::HtmlExample.new(code)
          elsif is_haml?
            example = CodeExampleRenderers::HamlExample.new(code)
          elsif is_slim?
            example = CodeExampleRenderers::SlimExample.new(code)
          end
          ERB.new(markup_example_template).result(example.get_binding)
        end

      elsif is_js?
        example = CodeExampleRenderers::JsExample.new(code)
        ERB.new(js_example_template).result(example.get_binding)

      elsif is_jsx?
        example = CodeExampleRenderers::JsxExample.new(code)
        ERB.new(jsx_example_template).result(example.get_binding)

      else
        example = CodeExampleRenderers::Example.new(code)
        ERB.new(unknown_example_template).result(example.get_binding)
      end
    end

    private

    attr_reader :code, :markdown_language, :path_to_custom_example_templates

    def template_filename(file)
      if path_to_custom_example_templates && File.file?(custom_file(file))
        custom_file(file)
      else
        File.join(File.dirname(__FILE__), '..', 'template', 'code_example_templates', "#{file}.html.erb")
      end
    end

    def custom_file(file)
      File.join(path_to_custom_example_templates, "#{file}.html.erb")
    end

    def markup_example_template
      File.read(template_filename('markup_example_template')).gsub(/\n */, '')
    end

    def markup_table_template
      File.read(template_filename('markup_table_template')).gsub(/\n */, '')
    end

    def js_example_template
      File.read(template_filename('js_example_template')).gsub(/\n */, '')
    end

    def jsx_example_template
      File.read(template_filename('jsx_example_template')).gsub(/\n */, '')
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
end
