module Hologram
  module CodeExampleRenderer
    class JsxExample < Example
      private

      def lexer
        @_lexer ||= Rouge::Lexer.find('html')
      end
    end
  end
end

