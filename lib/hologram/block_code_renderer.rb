require 'erb'

module Hologram
  class BlockCodeRenderer
    def initialize(code, markdown_language)
      @code = code
      @markdown_language = markdown_language
    end

    def render
      if is_table? && table_template
        examples = code.split("\n\n").map { |code_snippit| example_class.new(code_snippit) }
        ERB.new(table_template).result(binding)
      else
        example = example_class.new(code)
        ERB.new(example_template).result(example.get_binding)
      end
    end

    private

    attr_reader :code, :markdown_language

    def example_class
      CodeExampleRenderers.example_class_for(example_type)
    end

    def example_template
      CodeExampleRenderers.example_template_for(example_type)
    end

    def table_template
      CodeExampleRenderers.table_template_for(example_type)
    end

    def example_type
      match = /(\w+)_example/.match(markdown_language)
      match ? match.captures.first : nil
    end

    def is_table?
      markdown_language && markdown_language.include?('example_table')
    end
  end
end
