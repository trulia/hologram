Hologram::CodeExampleRenderer::Factory.define 'haml' do
  lexer { Rouge::Lexer.find('haml') }

  rendered_example do |code|
    begin
      require 'haml'
    rescue LoadError
      raise "haml must be present for you to use haml"
    end

    haml_engine = Haml::Engine.new(code.strip)
    haml_engine.render(Object.new, {})
  end
end

