module Hologram
  class DocBuilder
    attr_accessor :source, :destination, :documentation_assets, :dependencies, :index, :base_path, :renderer, :doc_blocks, :pages
    attr_reader :errors
    attr :doc_assets_dir, :output_dir, :input_dir, :header_erb, :footer_erb

    def self.from_yaml(yaml_file)
      config = YAML::load_file(yaml_file)
      raise SyntaxError if !config.is_a? Hash

      new(config.merge(
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
      @dependencies = options.fetch('dependencies', [])
      @index = options['index']
      @base_path = options.fetch('base_path', Dir.pwd)
      @renderer = options.fetch('renderer', MarkdownRenderer)
      @source = options['source']
      @destination = options['destination']
      @documentation_assets = options['documentation_assets']

      setup_header_footer
    end

    def build
      return false if !is_valid?
      @output_dir = real_path(destination)
      @doc_assets_dir = real_path(documentation_assets)
      @input_dir = real_path(source)

      current_path = Dir.pwd
      Dir.chdir(base_path)
      # Create the output directory if it doesn't exist
      FileUtils.mkdir_p(destination) unless File.directory?(destination)
      # the real work happens here.
      build_docs
      Dir.chdir(current_path)
      DisplayMessage.success("Build completed. (-: ")
      true
    end

    def is_valid?
      errors.clear
      errors << "No source directory specified in the config file" if !source
      errors << "No destination directory specified in the config" if !destination
      errors << "No documentation assets directory specified" if !documentation_assets

      errors << "Can not read source directory (#{source}), does it exist?" if source && !real_path(source)
      errors << "Can not read destination directory (#{destination}), does it exist?" if destination && !real_path(destination)
      errors << "Can not read documentation_assets directory (#{documentation_assets}), does it exist?" if documentation_assets && !real_path(documentation_assets)
      errors.empty?
    end

    private

    def real_path(dir)
      return if !File.directory?(String(dir))
      Pathname.new(dir).realpath
    end

    def build_docs
      doc_parser = DocParser.new(input_dir, index)
      @pages, @categories = doc_parser.parse

      if index && !@pages.has_key?(index + '.html')
        DisplayMessage.warning("Could not generate index.html, there was no content generated for the category #{config['index']}.")
      end

      write_docs(output_dir, doc_assets_dir)
      copy_dependencies
      copy_assets if doc_assets_dir
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
      markdown = Redcarpet::Markdown.new(renderer, { :fenced_code_blocks => true, :tables => true })
      tpl_vars = TemplateVariables.new({:categories => @categories})
      #generate html from markdown
      @pages.each do |file_name, page|
        fh = get_fh(output_dir, file_name)
        title = page[:blocks].empty? ? "" : page[:blocks][0][:category]
        tpl_vars.set_args({:title =>title, :file_name => file_name, :blocks => page[:blocks]})
        binding = tpl_vars.get_binding
        # generate doc nav html

        fh.write(header_erb.result(binding)) if header_erb
        fh.write(markdown.render(page[:md]))
        fh.write(footer_erb.result(binding)) if footer_erb

        fh.close()
      end
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
