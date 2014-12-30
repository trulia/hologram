require 'hologram/code_example_renderer/example'
require 'hologram/code_example_renderer/template'

module Hologram
  module CodeExampleRenderer
    class << self
      def register(example_type, args)
        example_types[example_type] = {
          example_class: args[:example_class],
          example_template: args[:example_template],
          table_template: args[:table_template]
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
        if example_types.has_key?(example_type)
          example_types[example_type][:example_template]
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
        if example_types.has_key?(example_type)
          example_types[example_type][:table_template]
        else
          nil
        end
      end

      def load_renderers_and_templates
        require 'hologram/code_example_renderer/factory'

        Dir[File.join(File.dirname(__FILE__), 'code_example_renderer', 'renderers', '*.rb')].each do |file|
          require file
        end
      end

      private

      def example_types
        @example_types ||= Hash.new
      end
    end
  end
end

