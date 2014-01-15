module Hologram
  class DocBuilder
    attr_accessor :doc_blocks, :config, :pages

    def init(args)
      @pages = {}
      @supported_extensions = ['.css', '.scss', '.less', '.sass', '.styl', '.js', '.md', '.markdown' ]

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
            rescue
              DisplayMessage.error("Could not load config file, try 'hologram init' to get started")
            end

            validate_config

            current_path = Dir.pwd
            base_path = Pathname.new(config_file)
            Dir.chdir(base_path.dirname)

            # the real work happens here.
            build_docs

            Dir.chdir(current_path)
            DisplayMessage.success("Build completed. (-: ")
          rescue RuntimeError => e
            DisplayMessage.error("#{e}")
          end
        end
      end
    end


    private
    def build_docs
      # Create the output directory if it doesn't exist
      FileUtils.mkdir_p(config['destination']) unless File.directory?(config['destination'])

      begin
        input_directory  = Pathname.new(config['source']).realpath
      rescue
        DisplayMessage.error("Can not read source directory (#{config['source'].inspect}), does it exist?")
      end

      output_directory = Pathname.new(config['destination']).realpath
      doc_assets       = Pathname.new(config['documentation_assets']).realpath unless !File.directory?(config['documentation_assets'])

      if doc_assets.nil?
        DisplayMessage.warning("Could not find documentation assets at #{config['documentation_assets']}")
      end

      @pages = DocParser.new(input_directory, config['index']).parse

      if config['index'] && !@pages.has_key?(config['index'] + '.html')
        DisplayMessage.warning("Could not generate index.html, there was no content generated for the category #{config['index']}.")
      end

      write_docs(output_directory, doc_assets)

      # Copy over dependencies
      if config['dependencies']
        config['dependencies'].each do |dir|
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
      renderer = get_markdown_renderer

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

      #generate html from markdown
      @pages.each do |file_name, page|
        fh = get_fh(output_directory, file_name)

        title = page[:blocks].empty? ? "" : page[:blocks][0][:category]

        tpl_vars = TemplateVariables.new(title, file_name, page[:blocks])

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


    def get_markdown_renderer
      if config['custom_markdown'].nil?
        renderer = Redcarpet::Markdown.new(HologramMarkdownRenderer, { :fenced_code_blocks => true, :tables => true })
      else
        begin
          load config['custom_markdown']
          renderer_class = File.basename(config['custom_markdown'], '.rb').split(/_/).map(&:capitalize).join
          DisplayMessage.info("Custom markdown renderer #{renderer_class} loaded.")
          renderer = Redcarpet::Markdown.new(Module.const_get(renderer_class), { :fenced_code_blocks => true, :tables => true })
        rescue LoadError => e
          DisplayMessage.error("Could not load #{config['custom_markdown']}.")
        rescue NameError => e
          DisplayMessage.error("Class #{renderer_class} not found in #{config['custom_markdown']}.")
        end
      end
      renderer
    end


    def validate_config
      unless @config.key?('source')
        DisplayMessage.error("No source directory specified in the config file")
      end

      unless @config.key?('destination')
        DisplayMessage.error("No destination directory specified in the config")
      end

      unless @config.key?('documentation_assets')
        DisplayMessage.error("No documentation assets directory specified")
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
