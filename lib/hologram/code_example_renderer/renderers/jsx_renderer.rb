Hologram::CodeExampleRenderer::Factory.define 'jsx' do
  example_template 'jsx_example_template'
  lexer { Rouge::Lexer.find('html') }
end
