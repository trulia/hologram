Hologram::CodeExampleRenderer::Factory.define 'slim' do
  example_template 'markup_example_template'
  table_template 'markup_table_template'
  lexer { Rouge::Lexer.find('slim') }

  rendered_example do |code|
    begin
      require 'slim'
    rescue LoadError
      raise "slim must be present for you to use slim"
    end

    slim_engine = Slim::Template.new { code.strip }
    slim_engine.render(Object.new, {})
  end
end
