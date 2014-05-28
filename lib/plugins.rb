module Hologram
  class Plugins

    attr_accessor :scope, :plugins, :config

    def initialize(config = nil)
      @scope = {}
      @plugins = []
      @config = config

      for plugin_file in config['plugins']
        load plugin_file
        plugin_class = Utils.get_class_name(plugin_file)
        Plugins.register(plugin_class)
        DisplayMessage.info("Loading plugin: #{plugin_class}")
      end
    end

    def self.register(plugin_class)
      @plugins.push(Module.const_get(renderer_class))
    end

    def self.block(config, comment_block, file)
      for plugin in @plugins
        @scope = plugin.finalize(@scope, config, comment_block, file)
      end
    end

    def self.finalize(pages)
      for plugin in @plugins
        plugin.finalize(@scope, pages)
      end
    end

  end
end
