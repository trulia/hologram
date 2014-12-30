module Hologram
  module CodeExampleRenderer
    class HamlExample < Example
      def rendered_example
        haml_engine.render(Object.new, {})
      end

      private

      def haml_engine
        safe_require 'haml', 'haml'
        Haml::Engine.new(code.strip)
      end

      def lexer
        @_lexer ||= Rouge::Lexer.find('haml')
      end
    end
  end
end

