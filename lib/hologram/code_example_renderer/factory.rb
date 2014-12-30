require 'hologram/code_example_renderer'

module Hologram
  module CodeExampleRenderer
    class Factory
      def self.define(example_type, &block)
        definition_proxy = DefinitionProxy.new
        definition_proxy.instance_eval(&block)

        example_class = Class.new(Example) do
          if definition_proxy.rendered_example_block
            define_method :rendered_example do
              definition_proxy.rendered_example_block.call(code)
            end
          end

          private

          define_method :lexer do
            definition_proxy.lexer_block.call
          end
        end

        CodeExampleRenderer.register(example_type,
          example_class: example_class,
          example_template: Template.new(definition_proxy.example_template_name).template,
          table_template: Template.new(definition_proxy.table_template_name).template,
        )
      end
    end

    class DefinitionProxy
      attr_reader :example_template_name, :table_template_name,
                  :lexer_block, :rendered_example_block

      def example_template(template_name)
        self.example_template_name = template_name
      end

      def table_template(template_name)
        self.table_template_name = template_name
      end

      def lexer(&block)
        self.lexer_block = block
      end

      def rendered_example(&block)
        self.rendered_example_block = block
      end

      private

      attr_writer :example_template_name, :table_template_name,
                  :lexer_block, :rendered_example_block
    end
  end
end
