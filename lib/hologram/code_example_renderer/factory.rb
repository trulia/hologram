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
        )
      end
    end

    class DefinitionProxy
      attr_reader :lexer_block, :rendered_example_block

      def lexer(&block)
        self.lexer_block = block
      end

      def rendered_example(&block)
        self.rendered_example_block = block
      end

      private

      attr_writer :lexer_block, :rendered_example_block
    end
  end
end
