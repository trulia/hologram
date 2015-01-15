module Hologram
  module CodeExampleRenderer
    class Example < Struct.new(:code)
      def rendered_example
        code
      end

      def code_example
        formatter.format(lexer.lex(code)).strip
      end

      def get_binding
        binding
      end

      private

      def formatter
        @_formatter ||= Rouge::Formatters::HTML.new(wrap: false)
      end

      def lexer
        @_lexer ||= Rouge::Lexer.find_fancy('guess', code)
      end
    end
  end
end
