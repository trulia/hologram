require 'optparse'

module Hologram
  class CLI
    attr_reader :args

    def initialize(args)
      @args = args
    end

    def run
      return setup if args[0] == 'init'

      #support passing the config file with no command line flag
      config = args[0].nil? ? 'hologram_config.yml' : args[0]
      root = nil

      OptionParser.new do |opt|
        opt.on_tail('-h', '--help', 'Show this message.') { puts opt; exit }
        opt.on_tail('-v', '--version', 'Show version.') { puts "hologram #{Hologram::VERSION}"; exit }
        opt.on('-c', '--config FILE', 'Path to config file. Default: hologram_config.yml') { |config_file| config = config_file }
        opt.on('-r', '--root DIR', 'Path to use as root directory. Default: current directory') { |root_dir| root = root_dir }
        opt.parse!(args)
      end

      if !root.nil?
        puts "Running out of #{root}"
        Dir.chdir root
      end

       config.nil? ? build : build(config)
    end

    private

    def build(config = 'hologram_config.yml')
      builder = DocBuilder.from_yaml(config)
      DisplayMessage.error(builder.errors.first) if !builder.is_valid?
      builder.build
    rescue CommenLoadError => e
      DisplayMessage.error(e.message)
    rescue Errno::ENOENT
      DisplayMessage.error("Could not load config file, try 'hologram init' to get started")
    end

    def setup
      DocBuilder.setup_dir
    rescue => e
      DisplayMessage.error("#{e}")
    end
  end
end
