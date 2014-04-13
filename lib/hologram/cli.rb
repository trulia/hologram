module Hologram
  class CLI
    attr_reader :arg

    def initialize(arg)
      @arg = arg
    end

    def run
      return setup if arg == 'init'
      arg.empty? ? build : build(arg)
    end

    private

    def build(config = 'hologram_config.yml')
      builder = DocBuilder.from_yaml(config)
      DisplayMessage.error(builder.errors.first) if !builder.is_valid?
      builder.build
    rescue Errno::ENOENT
      DisplayMessage.error("Could not load config file, try 'hologram init' to get started")
    rescue => e
      DisplayMessage.error(e.message)
    end

    def setup
      DocBuilder.setup_dir
    rescue => e
      DisplayMessage.error("#{e}")
    end
  end
end
