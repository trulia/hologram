Dir[File.join(File.dirname(__FILE__), 'code_example_renderer', '*')].each do |file|
  require file
end

module Hologram
  module CodeExampleRenderer
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
          Template.new('markup_example_template').template
        when 'haml'
          Template.new('markup_example_template').template
        when 'slim'
          Template.new('markup_example_template').template
        when 'js'
          Template.new('js_example_template').template
        when 'jsx'
          Template.new('jsx_example_template').template
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
          Template.new('markup_table_template').template
        else
          nil
        end
      end
    end
  end
end
