module Hologram
  class Plugins

    attr_accessor :plugins

    def initialize(config = {}, args)
      @plugins = []

      if config.has_key?('plugins')
        for plugin_file in config['plugins']
          plugin_path = Pathname.new(plugin_file).realpath
          load plugin_path
          plugin_class = Utils.get_class_name(plugin_file)
          register(plugin_class, config, args)
        end
      end
    end

    def register(plugin_class, config, args)
      clazz = Object.const_get(plugin_class)
      obj = clazz.new(config, args)
      if obj.is_active?
        DisplayMessage.info("Plugin active: #{plugin_class}")
      else
        DisplayMessage.info("Plugin not active: #{plugin_class}")
      end

      @plugins.push(obj)
    end

    def block(comment_block, file)
      for plugin in @plugins
        #We parse comment blocks even when the plugin is not active,
        #this allows us to remove the plugin's data blocks from the
        #markdown output
        plugin.parse_block(comment_block, file)
      end
    end

    def finalize(pages)
      for plugin in @plugins
        if plugin.is_active?
          plugin.finalize(pages)
        end
      end
    end

  end
end
