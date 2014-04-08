module Hologram
  class DocBuilder
    attr_accessor :source, :destination, :documentation_assets, :dependencies, :index, :base_path, :renderer, :doc_blocks, :pages

    def init(args)
      @pages = {}

      begin
        if args[0] == 'init' then
          if File.exists?("hologram_config.yml")
            DisplayMessage.warning("Cowardly refusing to overwrite existing hologram_config.yml")
          else
            FileUtils.cp_r INIT_TEMPLATE_FILES, Dir.pwd
            new_files = ["hologram_config.yml", "doc_assets/", "doc_assets/_header.html", "doc_assets/_footer.html"]
            DisplayMessage.created(new_files)
          end
        else
          begin
            config_file = args[0] ? args[0] : 'hologram_config.yml'

            begin
              @config = YAML::load_file(config_file)
            rescue SyntaxError => e
              DisplayMessage.error("Could not load config file, check the syntax or try 'hologram init' to get started")
            rescue
              DisplayMessage.error("Could not load config file, try 'hologram init' to get started")
            end

            if @config.is_a? Hash

              validate_config

              current_path = Dir.pwd
              base_path = Pathname.new(config_file)
              Dir.chdir(base_path.dirname)

              # the real work happens here.
              build_docs

              Dir.chdir(current_path)
              DisplayMessage.success("Build completed. (-: ")
            else
              DisplayMessage.error("Could not read config file, check the syntax or try 'hologram init' to get started")
            end
          rescue RuntimeError => e
            DisplayMessage.error("#{e}")
          end
        end
      end
    end

    def self.from_yaml(yaml_file)
      config = YAML::load_file(yaml_file)
      raise SyntaxError if !config.is_a? Hash
      validate_config(config)

      new(config.merge(
        'base_path' => Pathname.new(yaml_file),
        'renderer' => get_markdown_renderer(config['custom_markdown'])
      ))

    rescue SyntaxError
      DisplayMessage.error("Could not load config file, check the syntax or try 'hologram init' to get started")
    rescue
      DisplayMessage.error("Could not load config file, try 'hologram init' to get started")
    end

    def self.setup_dir
      if File.exists?("hologram_config.yml")
        DisplayMessage.warning("Cowardly refusing to overwrite existing hologram_config.yml")
        return
      end

      FileUtils.cp_r INIT_TEMPLATE_FILES, Dir.pwd
      new_files = ["hologram_config.yml", "doc_assets/", "doc_assets/_header.html", "doc_assets/_footer.html"]
      DisplayMessage.created(new_files)
    end

    def self.validate_config(config)
      unless config.key?('source')
        DisplayMessage.error("No source directory specified in the config file")
      end

      unless config.key?('destination')
        DisplayMessage.error("No destination directory specified in the config")
      end

      unless config.key?('documentation_assets')
        DisplayMessage.error("No documentation assets directory specified")
      end
    end

    def self.get_markdown_renderer(custom_markdown = nil)
      if custom_markdown.nil?
        renderer = Redcarpet::Markdown.new(HologramMarkdownRenderer, { :fenced_code_blocks => true, :tables => true })
      else
        begin
          load custom_markdown
          renderer_class = File.basename(custom_markdown, '.rb').split(/_/).map(&:capitalize).join
          DisplayMessage.info("Custom markdown renderer #{renderer_class} loaded.")
          renderer = Redcarpet::Markdown.new(Module.const_get(renderer_class), { :fenced_code_blocks => true, :tables => true })
        rescue LoadError => e
          DisplayMessage.error("Could not load #{custom_markdown}.")
        rescue NameError => e
          DisplayMessage.error("Class #{renderer_class} not found in #{custom_markdown}.")
        end
      end
      renderer
    end

    def initialize(config)
      @pages = {}
      @source = config['source']
      @destination = config['destination']
      @documentation_assets = config['documentation_assets']
      @dependencies = config['dependencies']
      @index = config['index']
      @base_path = config['base_path']
      @renderer = config['renderer']
    end

    def build
      current_path = Dir.pwd
      Dir.chdir(base_path.dirname)
      # the real work happens here.
      build_docs
      Dir.chdir(current_path)
      DisplayMessage.success("Build completed. (-: ")
    end

    private

    def build_docs
      # Create the output directory if it doesn't exist
      FileUtils.mkdir_p(destination) unless File.directory?(destination)

      begin
        input_directory  = Pathname.new(source).realpath
      rescue
        DisplayMessage.error("Can not read source directory (#{source.inspect}), does it exist?")
      end

      output_directory = Pathname.new(destination).realpath
      doc_assets       = Pathname.new(documentation_assets).realpath unless !File.directory?(documentation_assets)

      if doc_assets.nil?
        DisplayMessage.warning("Could not find documentation assets at #{documentation_assets}")
      end

      begin
        doc_parser = DocParser.new(input_directory, index)
        @pages, @categories = doc_parser.parse
      rescue CommentLoadError => e
        DisplayMessage.error(e.message)
      end

      if index && !@pages.has_key?(index + '.html')
        DisplayMessage.warning("Could not generate index.html, there was no content generated for the category #{config['index']}.")
      end

      write_docs(output_directory, doc_assets)

      # Copy over dependencies
      if dependencies
        dependencies.each do |dir|
          begin
            dirpath  = Pathname.new(dir).realpath
            if File.directory?("#{dir}")
              `rm -rf #{output_directory}/#{dirpath.basename}`
              `cp -R #{dirpath} #{output_directory}/#{dirpath.basename}`
            end
          rescue
            DisplayMessage.warning("Could not copy dependency: #{dir}")
          end
        end
      end

      if !doc_assets.nil?
        Dir.foreach(doc_assets) do |item|
         # ignore . and .. directories and files that start with
         # underscore
         next if item == '.' or item == '..' or item.start_with?('_')
         `rm -rf #{output_directory}/#{item}`
         `cp -R #{doc_assets}/#{item} #{output_directory}/#{item}`
        end
      end
    end


    def write_docs(output_directory, doc_assets)
      # load the markdown renderer we are going to use

      if File.exists?("#{doc_assets}/_header.html")
        header_erb = ERB.new(File.read("#{doc_assets}/_header.html"))
      elsif File.exists?("#{doc_assets}/header.html")
        header_erb = ERB.new(File.read("#{doc_assets}/header.html"))
      else
        header_erb = nil
        DisplayMessage.warning("No _header.html found in documentation assets. Without this your css/header will not be included on the generated pages.")
      end

      if File.exists?("#{doc_assets}/_footer.html")
        footer_erb = ERB.new(File.read("#{doc_assets}/_footer.html"))
      elsif File.exists?("#{doc_assets}/footer.html")
        footer_erb = ERB.new(File.read("#{doc_assets}/footer.html"))
      else
        footer_erb = nil
        DisplayMessage.warning("No _footer.html found in documentation assets. This might be okay to ignore...")
      end

      tpl_vars = TemplateVariables.new({:categories => @categories})
      #generate html from markdown
      @pages.each do |file_name, page|
        fh = get_fh(output_directory, file_name)

        title = page[:blocks].empty? ? "" : page[:blocks][0][:category]

        tpl_vars.set_args({:title =>title, :file_name => file_name, :blocks => page[:blocks]})

        # generate doc nav html
        unless header_erb.nil?
          fh.write(header_erb.result(tpl_vars.get_binding))
        end

        # write the docs
        begin
          fh.write(renderer.render(page[:md]))
        rescue Exception => e
          DisplayMessage.error(e.message)
        end

        # write the footer
        unless footer_erb.nil?
          fh.write(footer_erb.result(tpl_vars.get_binding))
        end

        fh.close()
      end
    end

    def get_file_name(str)
      str = str.gsub(' ', '_').downcase + '.html'
    end

    def get_fh(output_directory, output_file)
      File.open("#{output_directory}/#{output_file}", 'w')
    end
  end
end
