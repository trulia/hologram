module Hologram
  class Plugin
    attr :active, :name

    # Plugin constructor:
    # +config+: This is the config object generated from the config file
    # hologram was loaded with
    # +args+: These are the command line arguments hologram was run with
    def initialize(config, args)
      @active = self.get_active(args);
    end

    def get_active(args)
      flagged = false
      OptionParser.new do |opt|
        opt.on_tail("--#{@name}") { flagged = true }
        begin
          opt.parse!(args)
        rescue OptionParser::InvalidOption
          flagged = false
        end
      end

      return flagged
    end

    def is_active?()
      @active
    end

    def parse_block(comment_block, file)

      plugin_sections = comment_block.markdown.scan(/^\s*\[\[\[plugin:#{Regexp.quote(@name)}(.*?)\]\]\]/m)

      if self.is_active?

        self.block(comment_block, file, !plugin_sections.empty?)

        for section in plugin_sections
          plugin_data = section[0]
          replace_text = self.plugin(plugin_data, comment_block, file)
          comment_block.markdown = comment_block.markdown.gsub("[[[plugin:#{@name}#{plugin_data}]]]", replace_text)
        end
      else
        # plugin is inactive, so remove it from our markdown
        for section in plugin_sections
          plugin_data = section[0]
          comment_block.markdown = comment_block.markdown.gsub("[[[plugin:#{@name}#{plugin_data}]]]", '')
        end
      end

    end

    # This is called on every block that hologram parses.
    # Params:
    # +comment_block+: This is a doc_block object. It provides name,
    # children, title, markdown, yml config accessors.
    # +filename+: The filename for the current file being processed
    # +has_plugin+: This is a boolean that is true if this comment block
    # has plugin data for this plugin and false otherwise.
    def block(comment_block, filename, has_plugin) end

    # This is called everytime parse_block encounters a [[[plugin:name ]]]
    # section.
    # Params:
    # +data+: The text inside the plugin section.
    # +block+: The current doc_block object
    # +filename+: The filename of the file the plugin section is in
    #
    # Returns: A string that will replace the plugin block in the
    # documentation
    def plugin(data, block, filename)
      return ""
    end


    # This method is called after hologram has processed all the source
    # files. Pages is a dictionary of html pages to be written. The key is
    # the file name while the value is the html source.
    def finalize(pages) end


  end
end
