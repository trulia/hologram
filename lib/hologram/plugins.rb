module Hologram
  class Plugins

    attr_accessor :plugins, :config, :args

    def initialize(config = {}, args)
      @plugins = []
      @config = config
      @args = args

      if config.has_key?('plugins')
        for plugin_file in config['plugins']

          plugin_path = Pathname.new(plugin_file).realpath
          load plugin_path
          plugin_class = Utils.get_class_name(plugin_file)
          register(plugin_class)
        end
      end
    end

    def register(plugin_class)
      clazz = Object.const_get(plugin_class)
      obj = clazz.new(@config, @args)
      if obj.is_active?
        DisplayMessage.info("Plugin active: #{plugin_class}")
        @plugins.push(obj)
      else
        DisplayMessage.info("Plugin not active: #{plugin_class}")
      end
    end

    def block(comment_block, file)
      for plugin in @plugins
        plugin.block(comment_block, file)
      end
    end

    def finalize(pages)
      for plugin in @plugins
        plugin.finalize(pages)
      end
    end

  end
end
