require "hologram/version"

require 'redcarpet'
require 'yaml'
require 'pygments'
require 'fileutils'
require 'pathname'
require 'erb'

require 'hologram_markdown_renderer'

module Hologram

  class DocumentBlock
    attr_accessor :name, :parent, :children, :title, :category, :markdown, :config, :heading

    def initialize(config = nil, markdown = nil)
      @children = {}
      set_members(config, markdown) if config and markdown
    end

    def set_members(config, markdown)
      @name     = config['name']
      @category = config['category']
      @title    = config['title']
      @parent   = config['parent']
      @markdown = markdown
    end

    def get_hash
      {:name => @name,
       :parent => @parent,
       :category => @category,
       :title => @title
      }
    end

    def is_valid?
      !!(@name && @markdown)
    end

    # sets the header tag based on how deep your nesting is
    def markdown_with_heading(heading = 1)
      @markdown = "\n\n<h#{heading.to_s} id=\"#{@name}\">#{@title}</h#{heading.to_s}>" + @markdown
    end
  end


  class DocBuilder
    attr_accessor :doc_blocks, :config, :pages

    INIT_TEMPLATE_PATH = File.expand_path('./template/', File.dirname(__FILE__)) + '/'
    INIT_TEMPLATE_FILES = [
      INIT_TEMPLATE_PATH + '/hologram_config.yml',
      INIT_TEMPLATE_PATH + '/doc_assets',
    ]

    def init(args)
      @pages = {}
      @supported_extensions = ['.css', '.scss', '.less', '.sass', '.styl', '.js', '.md', '.markdown' ]

      begin
        if args[0] == 'init' then

          if File.exists?("hologram_config.yml")
            puts "Cowardly refusing to overwrite existing hologram_config.yml".yellow
          else
            FileUtils.cp_r INIT_TEMPLATE_FILES, Dir.pwd
            puts "Created the following files and directories:"
            puts "  hologram_config.yml"
            puts "  doc_assets/"
            puts "  doc_assets/_header.html"
            puts "  doc_assets/_footer.html"
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
            puts "Build completed. (-: ".green
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
        DisplayMessage.error("Can not read source directory, does it exist?")
      end

      output_directory = Pathname.new(config['destination']).realpath
      doc_assets       = Pathname.new(config['documentation_assets']).realpath unless !File.directory?(config['documentation_assets'])

      if doc_assets.nil?
        DisplayMessage.warning("Could not find documentation assets at #{config['documentation_assets']}")
      end

      # recursively traverse our directory structure looking for files that
      # match our "parseable" file types. Open those files pulling out any
      # comments matching the hologram doc style /*doc */ and create DocBlock
      # objects from those comments, then add those to a collection object which
      # is then returned.
      doc_block_collection = process_dir(input_directory)

      # doc blocks can define parent/child relationships that will nest their
      # documentation appropriately. we can't put everything into that structure
      # on our first pass through because there is no guarantee we'll parse files
      # in the correct order. This step takes the full collection and creates the
      # proper structure.
      doc_block_collection.create_nested_structure

      # hand off our properly nested collection to the output generator
      build_pages_from_doc_blocks(doc_block_collection.doc_blocks)

      # if we have an index category defined in our config copy that
      # page to index.html
      if config['index']
        if @pages.has_key?(config['index'] + '.html')
          @pages['index.html'] = @pages[config['index'] + '.html']
        else
          DisplayMessage.warning("Could not generate index.html, there was no content generated for the category #{config['index']}.")
        end
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


    def process_dir(base_directory)
      #get all directories in our library folder
      doc_block_collection = DocBlockCollection.new
      directories = Dir.glob("#{base_directory}/**/*/")
      directories.unshift(base_directory)

      directories.each do |directory|
        # filter and sort the files in our directory
        files = []
        Dir.foreach(directory).select{ |file| is_supported_file_type?(file) }.each do |file|
          files << file
        end
        files.sort!
        process_files(files, directory, doc_block_collection)
      end
      doc_block_collection
    end


    def process_files(files, directory, doc_block_collection)
      files.each do |input_file|
        if input_file.end_with?('md')
          @pages[File.basename(input_file, '.md') + '.html'] = {:md => File.read("#{directory}/#{input_file}"), :blocks => []}
        else
          process_file("#{directory}/#{input_file}", doc_block_collection)
        end
      end
    end


    def process_file(file, doc_block_collection)
      file_str = File.read(file)
      # get any comment blocks that match the patterns:
      # .sass: //doc (follow by other lines proceeded by a space)
      # other types: /*doc ... */
      if file.end_with?('.sass')
        hologram_comments = file_str.scan(/\s*\/\/doc\s*((( [^\n]*\n)|\n)+)/)
      else
        hologram_comments = file_str.scan(/^\s*\/\*doc(.*?)\*\//m)
      end
      return unless hologram_comments

      hologram_comments.each do |comment_block|
        doc_block_collection.add_doc_block(comment_block[0])
      end
    end


    def build_pages_from_doc_blocks(doc_blocks, output_file = nil, depth = 1)
      doc_blocks.sort.map do |key, doc_block|

        # if the doc_block has a category set then use that, this will be
        # true of all top level doc_blocks. The output file they set will then
        # be passed into the recursive call for adding children to the output
        output_file = get_file_name(doc_block.category) if doc_block.category

        if !@pages.has_key?(output_file)
          @pages[output_file] = {:md => "", :blocks => []}
        end

        @pages[output_file][:blocks].push(doc_block.get_hash)
        @pages[output_file][:md] << doc_block.markdown_with_heading(depth)

        if doc_block.children
          depth += 1
          build_pages_from_doc_blocks(doc_block.children, output_file, depth)
          depth -= 1
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
          puts "Custom markdown renderer #{renderer_class} loaded."
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


    def is_supported_file_type?(file)
      @supported_extensions.include?(File.extname(file))
    end


    def get_file_name(str)
      str = str.gsub(' ', '_').downcase + '.html'
    end


    def get_fh(output_directory, output_file)
      File.open("#{output_directory}/#{output_file}", 'w')
    end
  end


  #Helper class for binding things for ERB
  class TemplateVariables
    attr_accessor :title, :file_name, :blocks

    def initialize(title, file_name, blocks)
      @title = title
      @file_name = file_name
      @blocks = blocks
    end

    def get_binding
      binding()
    end
  end

  class DocBlockCollection
    attr_accessor :doc_blocks

    def initialize
      @doc_blocks = {}
    end

    # this should throw an error if we have a match, but no yaml_match
    def add_doc_block(comment_block)
      yaml_match = /^\s*---\s(.*?)\s---$/m.match(comment_block)
      return unless yaml_match

      markdown = comment_block.sub(yaml_match[0], '')

      begin
        config = YAML::load(yaml_match[1])
      rescue
        DisplayMessage.error("Could not parse YAML:\n#{yaml_match[1]}")
      end

      if config['name'].nil?
        DisplayMessage.warning("Missing required name config value. This hologram comment will be skipped. \n #{config.inspect}")
      else
        doc_block = DocumentBlock.new(config, markdown)
      end

      @doc_blocks[doc_block.name] = doc_block if doc_block.is_valid?
    end

    def create_nested_structure
      blocks_to_remove_from_top_level = []
      @doc_blocks.each do |key, doc_block|
        # don't do anything to top level doc_blocks
        next if !doc_block.parent

        parent = @doc_blocks[doc_block.parent]
        parent.children[doc_block.name] = doc_block
        doc_block.parent = parent
        blocks_to_remove_from_top_level << doc_block.name
      end

      blocks_to_remove_from_top_level.each do |key|
        @doc_blocks.delete(key)
      end
    end
  end

end



class DisplayMessage
  def self.error(message)
    if RUBY_VERSION.to_f > 1.8 then
      puts "(\u{256F}\u{00B0}\u{25A1}\u{00B0}\u{FF09}\u{256F}".green + "\u{FE35} \u{253B}\u{2501}\u{253B} ".yellow + " Build not complete.".red
    else
      puts "Build not complete.".red
    end
      puts " #{message}"
      exit 1
  end

  def self.warning(message)
    puts "Warning: ".yellow + message
  end
end


class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end

  def pink
    colorize(35)
  end
end
