module Hologram
  module Utils
    def self.get_markdown_renderer(custom_markdown = nil)
      return MarkdownRenderer if custom_markdown.nil?

      md_file = Pathname.new(custom_markdown).realpath
      load md_file
      renderer_class = self.get_class_name(custom_markdown)
      DisplayMessage.info("Custom markdown renderer #{renderer_class} loaded.")
      Module.const_get(renderer_class)
    rescue LoadError => e
      DisplayMessage.error("Could not load #{custom_markdown}.")
    rescue NameError => e
      DisplayMessage.error("Class #{renderer_class} not found in #{custom_markdown}.")
    end

    def self.get_class_name(file)
      File.basename(file, '.rb').split(/_/).map(&:capitalize).join
    end
  end
end
