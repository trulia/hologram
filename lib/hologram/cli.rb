require 'optparse'

module Hologram
  class CLI
    attr_reader :args

    def initialize(args)
      @args = args
    end

    def run
      return setup if args[0] == 'init'
      extra_args = []

      #support passing the config file with no command line flag
      config = args[0].nil? ? 'hologram_config.yml' : args[0]

      OptionParser.new do |opt|
        opt.on_tail('-h', '--help', 'Show this message.') { puts opt; exit }
        opt.on_tail('-v', '--version', 'Show version.') { puts "hologram #{Hologram::VERSION}"; exit }
        opt.on('-c', '--config FILE', 'Path to config file. Default: hologram_config.yml') { |config_file| config = config_file }
        begin
          opt.parse!(args)
        rescue OptionParser::InvalidOption => e
          extra_args.push(e.to_s.sub(/invalid option:\s+/, ''))
        end

      end

      config.nil? ? build(extra_args) : build(extra_args, config)

    end

    private
    def build(extra_args = [], config = 'hologram_config.yml')
      builder = DocBuilder.from_yaml(config, extra_args)
      DisplayMessage.error(builder.errors.first) if !builder.is_valid?
      builder.build
    rescue CommentLoadError, NoCategoryError => e
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
