Hologram::CodeExampleRenderer::Factory.define 'html' do
  example_template 'markup_example_template'
  table_template 'markup_table_template'
  lexer { Rouge::Lexer.find('html') }
end

