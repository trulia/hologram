module Hologram
  class Plugins

    attr_accessor :scope, :plugins, :config

    def initialize(config = {})
      @scope = {}
      @plugins = []
      @config = config

      if config.has_key?('plugins')
        for plugin_file in config['plugins']

          plugin_path = Pathname.new(plugin_file).realpath
          load plugin_path
          plugin_class = Utils.get_class_name(plugin_file)
          register(plugin_class)
          DisplayMessage.info("Loading plugin: #{plugin_class}")
        end
      end
    end

    def register(plugin_class)
      @plugins.push(Object.const_get(plugin_class))
    end

    def block(comment_block, file)
      for plugin in @plugins
        @scope = plugin.block(@scope, @config, comment_block, file)
      end
    end

    def finalize(pages)
      for plugin in @plugins
        plugin.finalize(@scope, @config, pages)
      end
    end

  end
end
