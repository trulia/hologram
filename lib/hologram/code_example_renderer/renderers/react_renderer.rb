require 'securerandom'

Hologram::CodeExampleRenderer::Factory.define 'react' do
  example_template 'markup_example_template'
  table_template 'markup_table_template'

  lexer { Rouge::Lexer.find(:html) }

  rendered_example do |code|
    div_id = SecureRandom.hex(10)
    [
      "<div id=\"#{div_id}\"></div>",
      "<script type=\"text/jsx\">",
      "  React.render(",
      "    #{code.strip},",
      "    document.getElementById('#{div_id}')",
      "  );",
      "</script>"
    ].join("\n")
  end
end
