Hologram::CodeExampleRenderer::Factory.define 'js' do
  example_template 'js_example_template'
  lexer { Rouge::Lexer.find('js') }
end

