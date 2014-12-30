require 'hologram/code_example_renderer/example'
require 'hologram/code_example_renderer/template'

module Hologram
  module CodeExampleRenderer
    class << self
      def register(example_type, args)
        example_types[example_type] = {
          example_class: args[:example_class]
        }
      end

      def example_class_for(example_type)
        if example_types.has_key?(example_type)
          example_types[example_type][:example_class]
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

      private

      def example_types
        @example_types ||= Hash.new
      end
    end
  end
end

require 'hologram/code_example_renderer/factory'

Dir[File.join(File.dirname(__FILE__), 'code_example_renderer', 'renderers', '*.rb')].each do |file|
  require file
end

