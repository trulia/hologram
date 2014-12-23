module Hologram
  module CodeExampleRenderers
    class Example < Struct.new(:code)
      def rendered_example
        code
      end

      def code_example
        formatter.format(lexer.lex(code))
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

      def safe_require(templating_library, language)
        begin
          require templating_library
        rescue LoadError
          raise "#{templating_library} must be present for you to use #{language}"
        end
      end
    end
  end
end
