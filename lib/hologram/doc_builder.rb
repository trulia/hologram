module Hologram
  class DocBuilder
    attr_accessor :source, :destination, :documentation_assets, :dependencies, :index, :base_path, :renderer, :doc_blocks, :pages
    attr :doc_assets_dir, :output_dir, :input_dir, :header_erb, :footer_erb

    def self.from_yaml(yaml_file)
      config = YAML::load_file(yaml_file)
      raise SyntaxError if !config.is_a? Hash
      validate_config(config)

      new(config.merge(
        'base_path' => Pathname.new(yaml_file),
        'renderer' => Utils.get_markdown_renderer(config['custom_markdown'])
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
      # Create the output directory if it doesn't exist
      FileUtils.mkdir_p(destination) unless File.directory?(destination)
      # the real work happens here.
      setup_paths
      setup_header_footer
      build_docs
      Dir.chdir(current_path)
      DisplayMessage.success("Build completed. (-: ")
    end

    private

    def setup_paths
      @input_dir = Pathname.new(source).realpath
      @output_dir = Pathname.new(destination).realpath
      @doc_assets_dir = Pathname.new(documentation_assets).realpath if File.directory?(documentation_assets)

      if doc_assets_dir.nil?
        DisplayMessage.warning("Could not find documentation assets at #{documentation_assets}")
      end
    rescue
      DisplayMessage.error("Can not read source directory (#{source.inspect}), does it exist?")
    end

    def build_docs
      doc_parser = DocParser.new(input_dir, index)
      @pages, @categories = doc_parser.parse

      if index && !@pages.has_key?(index + '.html')
        DisplayMessage.warning("Could not generate index.html, there was no content generated for the category #{config['index']}.")
      end

      write_docs(output_dir, doc_assets_dir)
      copy_dependencies if dependencies
      copy_assets if doc_assets_dir

    rescue CommentLoadError => e
      DisplayMessage.error(e.message)
    end

    def copy_assets
      Dir.foreach(doc_assets_dir) do |item|
        # ignore . and .. directories and files that start with
        # underscore
        next if item == '.' or item == '..' or item.start_with?('_')
        `rm -rf #{output_dir}/#{item}`
        `cp -R #{doc_assets_dir}/#{item} #{output_dir}/#{item}`
      end
    end

    def copy_dependencies
      dependencies.each do |dir|
        begin
          dirpath  = Pathname.new(dir).realpath
          if File.directory?("#{dir}")
            `rm -rf #{output_dir}/#{dirpath.basename}`
            `cp -R #{dirpath} #{output_dir}/#{dirpath.basename}`
          end
        rescue
          DisplayMessage.warning("Could not copy dependency: #{dir}")
        end
      end
    end

    def write_docs(output_dir, doc_assets_dir)
      tpl_vars = TemplateVariables.new({:categories => @categories})
      #generate html from markdown
      @pages.each do |file_name, page|
        fh = get_fh(output_dir, file_name)
        title = page[:blocks].empty? ? "" : page[:blocks][0][:category]
        tpl_vars.set_args({:title =>title, :file_name => file_name, :blocks => page[:blocks]})
        binding = tpl_vars.get_binding
        # generate doc nav html

        fh.write(header_erb.result(binding)) if header_erb
        fh.write(renderer.render(page[:md]))
        fh.write(footer_erb.result(binding)) if footer_erb

        fh.close()
      end

    rescue Exception => e
      DisplayMessage.error(e.message)
    end

    def setup_header_footer
      # load the markdown renderer we are going to use

      if File.exists?("#{doc_assets_dir}/_header.html")
        @header_erb = ERB.new(File.read("#{doc_assets_dir}/_header.html"))
      elsif File.exists?("#{doc_assets_dir}/header.html")
        @header_erb = ERB.new(File.read("#{doc_assets_dir}/header.html"))
      else
        @header_erb = nil
        DisplayMessage.warning("No _header.html found in documentation assets. Without this your css/header will not be included on the generated pages.")
      end

      if File.exists?("#{doc_assets_dir}/_footer.html")
        @footer_erb = ERB.new(File.read("#{doc_assets_dir}/_footer.html"))
      elsif File.exists?("#{doc_assets_dir}/footer.html")
        @footer_erb = ERB.new(File.read("#{doc_assets_dir}/footer.html"))
      else
        @footer_erb = nil
        DisplayMessage.warning("No _footer.html found in documentation assets. This might be okay to ignore...")
      end
    end

    def get_file_name(str)
      str.gsub(' ', '_').downcase + '.html'
    end

    def get_fh(output_dir, output_file)
      File.open("#{output_dir}/#{output_file}", 'w')
    end
  end
end
