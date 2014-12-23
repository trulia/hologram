module Hologram
  module CodeExampleRenderers
    class JsExample < Example
      private

      def lexer
        @_lexer ||= Rouge::Lexer.find('js')
      end
    end
  end
end

