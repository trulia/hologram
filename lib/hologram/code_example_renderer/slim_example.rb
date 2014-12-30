module Hologram
  module CodeExampleRenderer
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

  end
end

