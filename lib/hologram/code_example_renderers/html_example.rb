module Hologram
  module CodeExampleRenderers
    class HtmlExample < Example
      private

      def lexer
        @_lexer ||= Rouge::Lexer.find('html')
      end
    end
  end
end

