class HologramMarkdownRenderer < Redcarpet::Render::HTML
  def block_code(code, language)
    if language and language.include?('example')
      if language.include?('js')
        # first actually insert the code in the docs so that it will run and make our example work.
        '<script>' + code + '</script>
        <div class="codeBlock jsExample">' + Pygments.highlight(code) + '</div>'
      else
        '<div class="codeExample">' + '<div class="exampleOutput">' + code + '</div>' + '<div class="codeBlock">' + Pygments.highlight(code) + '</div>' + '</div>'
      end
    else
      '<div class="codeBlock">' + Pygments.highlight(code) + '</div>'
    end      
  end
end
