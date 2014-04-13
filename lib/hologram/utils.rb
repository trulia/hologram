module Hologram
  module Utils
    def self.get_markdown_renderer(custom_markdown = nil)
      if custom_markdown.nil?
        renderer = Redcarpet::Markdown.new(HologramMarkdownRenderer, { :fenced_code_blocks => true, :tables => true })
      else
        begin
          load custom_markdown
          renderer_class = File.basename(custom_markdown, '.rb').split(/_/).map(&:capitalize).join
          DisplayMessage.info("Custom markdown renderer #{renderer_class} loaded.")
          renderer = Redcarpet::Markdown.new(Module.const_get(renderer_class), { :fenced_code_blocks => true, :tables => true })
        rescue LoadError => e
          DisplayMessage.error("Could not load #{custom_markdown}.")
        rescue NameError => e
          DisplayMessage.error("Class #{renderer_class} not found in #{custom_markdown}.")
        end
      end
      renderer
    end
  end
end
