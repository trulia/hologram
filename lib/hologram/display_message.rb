module Hologram
  module DisplayMessage
    @@quiet = false
    @@exit_on_warnings = false

    def self.quiet!
      @@quiet = true
      return self
    end

    def self.show!
      @@quiet = false
      return self
    end

    def self.quiet?
      @@quiet
    end

    def self.exit_on_warnings!
      @@exit_on_warnings = true
    end

    def self.continue_on_warnings!
      @@exit_on_warnings = false
    end

    def self.puts(str)
      return if quiet?
      super(str)
    end

    def self.info(message)
      puts message
    end

    def self.error(message)
      if RUBY_VERSION.to_f > 1.8 then
        puts angry_table_flipper + red(" Build not complete.")
      else
        puts red("Build not complete.")
      end

      puts " #{message}"
      exit 1
    end

    def self.created(files)
      puts "Created the following files and directories:"
      files.each do |file_name|
        puts "  #{file_name}"
      end
    end

    def self.warning(message)
      puts yellow("Warning: #{message}")
      if @@exit_on_warnings
        puts red("Exiting due to warning")
        exit 1
      end
    end

    def self.success(message)
      puts green(message)
    end

    def self.angry_table_flipper
      green("(\u{256F}\u{00B0}\u{25A1}\u{00B0}\u{FF09}\u{256F}") + red("\u{FE35} \u{253B}\u{2501}\u{253B} ")
    end

    # colorization
    def self.colorize(color_code, str)
      "\e[#{color_code}m#{str}\e[0m"
    end

    def self.red(str)
      colorize(31, str)
    end

    def self.green(str)
      colorize(32, str)
    end

    def self.yellow(str)
      colorize(33, str)
    end

    def self.pink(str)
      colorize(35, str)
    end
  end
end
