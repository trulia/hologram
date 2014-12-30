module Hologram
  module CodeExampleRenderer
    class HtmlExample < Example
      private

      def lexer
        @_lexer ||= Rouge::Lexer.find('html')
      end
    end
  end
end

