module Hologram
  class DocBuilder
    attr_accessor :source, :destination, :documentation_assets, :dependencies, :index, :base_path, :renderer, :doc_blocks, :pages, :config_yml
    attr_reader :errors
    attr :doc_assets_dir, :output_dir, :input_dir, :header_erb, :footer_erb

    def self.from_yaml(yaml_file)

      #Change dir so that our paths are relative to the config file
      base_path = Pathname.new(yaml_file)
      yaml_file = base_path.realpath.to_s
      Dir.chdir(base_path.dirname)

      config = YAML::load_file(yaml_file)
      raise SyntaxError if !config.is_a? Hash

      new(config.merge(
        'config_yml' => config,
        'base_path' => Pathname.new(yaml_file).dirname,
        'renderer' => Utils.get_markdown_renderer(config['custom_markdown'])
      ))

    rescue SyntaxError, ArgumentError, Psych::SyntaxError
      raise SyntaxError, "Could not load config file, check the syntax or try 'hologram init' to get started"
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

    def initialize(options)
      @pages = {}
      @errors = []
      @dependencies = options.fetch('dependencies', nil) || []
      @index = options['index']
      @base_path = options.fetch('base_path', Dir.pwd)
      @renderer = options.fetch('renderer', MarkdownRenderer)
      @source = Array(options['source'])
      @destination = options['destination']
      @documentation_assets = options['documentation_assets']
      @config_yml = options['config_yml']
    end

    def build
      set_dirs
      return false if !is_valid?

      set_header_footer
      current_path = Dir.pwd
      Dir.chdir(base_path)
      # Create the output directory if it doesn't exist
      if !output_dir
        FileUtils.mkdir_p(destination)
        set_dirs #need to reset output_dir post-creation for build_docs.
      end
      # the real work happens here.
      build_docs
      Dir.chdir(current_path)
      DisplayMessage.success("Build completed. (-: ")
      true
    end

    def is_valid?
      errors.clear
      set_dirs
      validate_source
      validate_destination
      validate_document_assets

      errors.empty?
    end

    private

    def validate_source
      errors << "No source directory specified in the config file" if source.empty?
      source.each do |dir|
        next if real_path(dir)
        errors << "Can not read source directory (#{dir}), does it exist?"
      end
    end

    def validate_destination
      errors << "No destination directory specified in the config" if !destination
    end

    def validate_document_assets
      errors << "No documentation assets directory specified" if !documentation_assets
    end

    def set_dirs
      @output_dir = real_path(destination)
      @doc_assets_dir = real_path(documentation_assets)
      @input_dir = multiple_paths(source)
    end

    def real_path(dir)
      return if !File.directory?(String(dir))
      Pathname.new(dir).realpath
    end

    def multiple_paths dirs
      Array(dirs).map { |dir| real_path(dir) }.compact
    end

    def build_docs
      doc_parser = DocParser.new(input_dir, index)
      @pages, @categories = doc_parser.parse

      if index && !@pages.has_key?(index + '.html')
        DisplayMessage.warning("Could not generate index.html, there was no content generated for the category #{index}.")
      end

      warn_missing_doc_assets
      write_docs
      copy_dependencies
      copy_assets
    end

    def copy_assets
      return unless doc_assets_dir
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

    def write_docs
      markdown = Redcarpet::Markdown.new(renderer, { :fenced_code_blocks => true, :tables => true })
      tpl_vars = TemplateVariables.new({:categories => @categories, :config => @config_yml, :pages => @pages})
      #generate html from markdown
      @pages.each do |file_name, page|
        if file_name.nil?
          raise NoCategoryError
        else
          if page[:blocks] && page[:blocks].empty?
            title = ''
          else
            title, _ = @categories.rassoc(file_name)
          end

          tpl_vars.set_args({:title => title, :file_name => file_name, :blocks => page[:blocks]})
          if page.has_key?(:erb)
            write_erb(file_name, page[:erb], tpl_vars.get_binding)
          else
            write_page(file_name, markdown.render(page[:md]), tpl_vars.get_binding)
          end
        end
      end
    end

    def write_erb(file_name, content, binding)
      fh = get_fh(output_dir, file_name)
      erb = ERB.new(content)
      fh.write(erb.result(binding))
    ensure
      fh.close
    end

    def write_page(file_name, body, binding)
      fh = get_fh(output_dir, file_name)
      fh.write(header_erb.result(binding)) if header_erb
      fh.write(body)
      fh.write(footer_erb.result(binding)) if footer_erb
    ensure
      fh.close
    end

    def set_header_footer
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

    def warn_missing_doc_assets
      return if doc_assets_dir
      DisplayMessage.warning("Could not find documentation assets at #{documentation_assets}")
    end
  end
end
