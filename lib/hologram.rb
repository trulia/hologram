require "hologram/version"

# require 'sass'
require 'redcarpet'
require 'yaml'
require 'pygments'
require 'fileutils'
require 'pathname'

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


module Hologram

  class DocumentBlock
    attr_accessor :name, :parent, :title, :category, :output, :output_file, :config 
    attr_reader :loaded

    def initialize(file)
      file = File.read(file)
      comment_match = /^\/\*(.*?)\*\//m.match(file)
      return false unless comment_match
      comment_block = comment_match[0]
      match = /^---\s(.*?)\s---$/m.match(comment_block)
      return false unless match
    
      yaml = match[0]
      markdown = comment_block.sub(yaml, '').sub('/*', '').sub('*/', '')

      @config = YAML::load(yaml)
      @parent = @config['parent']
      @name = @config['name']
      @category = @config['category']
      @title = @config['title']

      @output = markdown
      @loaded = true
    end

    def has_block?
      @loaded
    end
  end

  class Builder
    attr_accessor :docblocks

    def init(args)
      @docblocks = {}
      begin 
        config = args ? YAML::load_file(args[0]) : YAML::load_file('hologram_config.yml')
        current_path = Dir.pwd
        base_path = Pathname.new(args[0])
        Dir.chdir(base_path.dirname)
        build(config)
        Dir.chdir(current_path)
        puts "Build successful. (-: ".green
      rescue Errno::ENOENT
        display_error("Could not load config file.")
      rescue RuntimeError => e
        display_error(" #{e}")
      end
    end

    private
    def display_error(message)
        puts "(\u{256F}\u{00B0}\u{25A1}\u{00B0}\u{FF09}\u{256F}".green + "\u{FE35} \u{253B}\u{2501}\u{253B} ".yellow + " Build not complete.".red 
        puts " #{message}"
        exit 1
    end

    def get_file_name(str)
      str = str.gsub(' ', '_').downcase + '.html'
    end


    def get_fh(output_directory, output_file)
      File.open("#{output_directory}/#{output_file}", 'w')
    end


    def process_file(file)
      doc_block = DocumentBlock.new(file)
      
      if doc_block.has_block?
        if doc_block.parent.nil?
          #parent file
          begin
            doc_block.output_file = get_file_name(doc_block.category)
          rescue NoMethodError => e
            display_error("No output file specified for #{file}. Missing parent or name config?")
          end

          @docblocks[doc_block.name] = doc_block;
          doc_block.output = "\n\n# #{doc_block.title}" + doc_block.output
        else
          #child file
          doc_block.output_file = @docblocks[doc_block.parent].output_file
          doc_block.output = "\n\n## #{doc_block.title}" + doc_block.output
        end
      end
      doc_block
    end

    def process_dir(base_directory)
      pages = {}

      #get all directories in our library folder
      directories = Dir.glob("#{base_directory}/**/*/")
      directories.unshift(base_directory)

      directories.each do |directory|

        # filter and sort the files in our directory
        files = []
        Dir.foreach(directory).select{ |file| is_supported_file_type?(file) }.each do |file|
          files << file
        end
        files.sort!

        process_files(pages, files, directory)
      end

      return pages
    end

    def process_files(pages, files, directory)
      files.each do |input_file|      
        if input_file.end_with?('md')
          pages[File.basename(input_file, '.md') + '.html'] = File.read("#{directory}/#{input_file}")
        else
          doc = process_file("#{directory}/#{input_file}")

          if doc.has_block?
            pages[doc.output_file] = "" if pages[doc.output_file].nil?
            pages[doc.output_file] << doc.output
          end
        end

      end
    end


    def build(config)
      if  !config.key?('source')
        raise "No source directory specified in the config file"
      end

      if  !config.key?('destination')
        raise "No destination directory specified in the config"
      end

      if  !config.key?('documentation_assets')
        raise "No documentation assets directory specified"
      end

      # Create the output directory if it doesn't exist
      unless File.directory?(config['source'])
        FileUtils.mkdir_p(config['source'])
      end

      input_directory  = Pathname.new(config['source']).realpath
      output_directory = Pathname.new(config['destination']).realpath
      doc_assets       = Pathname.new(config['documentation_assets']).realpath

      if config['custom_markdown'].nil?
        renderer = Redcarpet::Markdown.new({ :fenced_code_blocks => true, :tables => true })
      else
        begin
          load config['custom_markdown']
          renderer_class = File.basename(config['custom_markdown'], '.rb').split(/_/).map(&:capitalize).join
          puts "Using #{renderer_class} markdown renderer."
          renderer = Redcarpet::Markdown.new(Module.const_get(renderer_class), { :fenced_code_blocks => true, :tables => true })
        rescue LoadError => e
          display_error("Could not load #{config['custom_markdown']}.")
        rescue NameError => e
          display_error("Class #{renderer_class} not found in #{config['custom_markdown']}.")
        end

      end

      #collect the markdown pages all together by category
      pages = process_dir(input_directory)


      #generate html from markdown
    
      pages.each do |file_name, markdown|
        fh = get_fh(output_directory, file_name)

        # generate doc nav html
        if File.exists?("#{doc_assets}/header.html")
          fh.write(File.read("#{doc_assets}/header.html"))
        end
        
        # write the docs
        fh.write(renderer.render(markdown))

        # write the footer
        if File.exists?("#{doc_assets}/footer.html")
          fh.write(File.read("#{doc_assets}/footer.html"))
        end

        fh.close()
      end

      config['additional_assets'].each do |dir|
        dirpath  = Pathname.new(dir).realpath
        if Dir.exists?("#{dir}")
          `rm -rf #{output_directory}/#{dirpath.basename}`
          `cp -R #{dirpath} #{output_directory}/#{dirpath.basename}`
        end
      end

      Dir.foreach(doc_assets) do |file|
        if file.start_with?('_')
          `rm -rf #{output_directory}/#{file.sub('_', '')}`
          `cp -R #{doc_assets}/#{file} #{output_directory}/#{file.sub('_', '')}`
        end
      end

    end

    def is_supported_file_type?(file)
      supported_extensions = ['.scss', '.js', '.md', '.markdown' ]
      supported_extensions.include?(File.extname(file))
    end
  end


end
