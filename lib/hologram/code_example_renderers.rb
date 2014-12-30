Dir[File.join(File.dirname(__FILE__), 'code_example_renderers', '*')].each do |file|
  require file
end

module Hologram
  module CodeExampleRenderers
    class << self
      def example_class_for(example_type)
        case example_type
        when 'html'
          HtmlExample
        when 'haml'
          HamlExample
        when 'slim'
          SlimExample
        when 'js'
          JsExample
        when 'jsx'
          JsxExample
        else
          Example
        end
      end

      def example_template_for(example_type)
        case example_type
        when 'html'
          File.read(template_filename('markup_example_template')).gsub(/\n */, '')
        when 'haml'
          File.read(template_filename('markup_example_template')).gsub(/\n */, '')
        when 'slim'
          File.read(template_filename('markup_example_template')).gsub(/\n */, '')
        when 'js'
          File.read(template_filename('js_example_template')).gsub(/\n */, '')
        when 'jsx'
          File.read(template_filename('jsx_example_template')).gsub(/\n */, '')
        else
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
      end

      def table_template_for(example_type)
        if ['html', 'haml', 'slim'].include?(example_type)
          File.read(template_filename('markup_table_template')).gsub(/\n */, '')
        else
          nil
        end
      end

      attr_writer :path_to_custom_example_templates
    end

    private

    class << self
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

      attr_reader :path_to_custom_example_templates
    end
  end
end
