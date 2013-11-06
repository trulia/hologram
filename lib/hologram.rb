# Copyright (c) 2013, Trulia, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#    * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#    * Neither the name of the Trulia, Inc. nor the
#      names of its contributors may be used to endorse or promote products
#      derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL TRULIA, INC. BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require "hologram/version"

require 'redcarpet'
require 'yaml'
require 'pygments'
require 'fileutils'
require 'pathname'

require 'hologram_markdown_renderer'

module Hologram


  class DocumentBlock
    attr_accessor :name, :parent, :children, :title, :category, :markdown, :output_file, :config

    def initialize(config = nil, markdown = nil)
      @children = {}
      set_members(config, markdown) if config and markdown
    end

    def set_members(config, markdown)
      @name     = config['name']
      @parent   = config['parent']
      @category = config['category']
      @title    = config['title']
      @markdown = markdown
    end

    def is_valid?
      @name && @markdown
    end
  end


  class Builder
    attr_accessor :doc_blocks, :config, :pages

    def init(args)
      @doc_blocks, @pages = {}, {}
      begin
        @config = args ? YAML::load_file(args[0]) : YAML::load_file('hologram_config.yml')
        validate_config

        #TODO: maybe this should move into build_docs
        current_path = Dir.pwd
        base_path = Pathname.new(args[0])
        Dir.chdir(base_path.dirname)

        build_docs

        Dir.chdir(current_path)
        puts "Build successful. (-: ".green
      rescue Errno::ENOENT
        display_error("Could not load config file.")
      rescue RuntimeError => e
        display_error("#{e}")
      end
    end


    private
    def build_docs
      # Create the output directory if it doesn't exist
      FileUtils.mkdir_p(config['destination']) unless File.directory?(config['destination'])

      input_directory  = Pathname.new(config['source']).realpath
      output_directory = Pathname.new(config['destination']).realpath
      doc_assets       = Pathname.new(config['documentation_assets']).realpath

      process_dir(input_directory)

      build_pages_from_doc_blocks(@doc_blocks)
      write_docs(output_directory, doc_assets)

      # Copy over dependencies
      if config['dependencies']
        config['dependencies'].each do |dir|
          dirpath  = Pathname.new(dir).realpath
          if File.directory?("#{dir}")
            `rm -rf #{output_directory}/#{dirpath.basename}`
            `cp -R #{dirpath} #{output_directory}/#{dirpath.basename}`
          end
        end
      end

      Dir.foreach(doc_assets) do |item|
       # ignore . and .. directories
       next if item == '.' or item == '..'
       `rm -rf #{output_directory}/#{item}`
       `cp -R #{doc_assets}/#{item} #{output_directory}/#{item}`
      end
    end


    def process_dir(base_directory)
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
        process_files(files, directory)
      end
    end


    def process_files(files, directory)
      files.each do |input_file|
        if input_file.end_with?('md')
          @pages[File.basename(input_file, '.md') + '.html'] = File.read("#{directory}/#{input_file}")
        else
          process_file("#{directory}/#{input_file}")
        end
      end
    end


    def process_file(file)
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
        doc_block = build_doc_block(comment_block[0])
        add_doc_block_to_collection(doc_block) if doc_block
      end
    end


    # this should throw an error if we have a match, but now yaml_match
    def build_doc_block(comment_block)
      yaml_match = /^\s*---\s(.*?)\s---$/m.match(comment_block)
      return unless yaml_match
      markdown = comment_block.sub(yaml_match[0], '')

      begin
        config = YAML::load(yaml_match[1])
      rescue
        display_error("Could not parse YAML:\n#{yaml_match[1]}")
      end

      if config['name'].nil?
        puts "Missing required name config value. This hologram comment will be skipped. \n #{config.inspect}"
      else
        doc_block = DocumentBlock.new(config, markdown)
      end
    end


    def add_doc_block_to_collection(doc_block)
      return unless doc_block.is_valid?
      if doc_block.parent.nil?
        #parent file
        begin
          doc_block.output_file = get_file_name(doc_block.category)
        rescue NoMethodError => e
          display_error("No output file specified. Missing category? \n #{doc_block.inspect}")
        end

        @doc_blocks[doc_block.name] = doc_block;
        doc_block.markdown = "\n\n# #{doc_block.title}" + doc_block.markdown
      else
        # child file
        parent_doc_block = @doc_blocks[doc_block.parent]
        if parent_doc_block
          doc_block.markdown = "\n\n## #{doc_block.title}" + doc_block.markdown
          parent_doc_block.children[doc_block.name] = doc_block
        else
          @doc_blocks[doc_block.parent] = DocumentBlock.new()
        end
      end
    end


    def build_pages_from_doc_blocks(doc_blocks, output_file = nil)
      doc_blocks.sort.map do |key, doc_block|
        output_file = doc_block.output_file || output_file
        @pages[output_file] ||= ""
        @pages[output_file] << doc_block.markdown
        if doc_block.children
          build_pages_from_doc_blocks(doc_block.children, output_file)
        end
      end
    end


    def write_docs(output_directory, doc_assets)
      # load the markdown renderer we are going to use
      renderer = get_markdown_renderer

      #generate html from markdown
      @pages.each do |file_name, markdown|
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
          display_error("Could not load #{config['custom_markdown']}.")
        rescue NameError => e
          display_error("Class #{renderer_class} not found in #{config['custom_markdown']}.")
        end
      end
      renderer
    end


    def validate_config
      unless @config.key?('source')
        raise "No source directory specified in the config file"
      end

      unless @config.key?('destination')
        raise "No destination directory specified in the config"
      end

      unless @config.key?('documentation_assets')
        raise "No documentation assets directory specified"
      end
    end


    def is_supported_file_type?(file)
      supported_extensions = ['.css', '.scss', '.less', '.sass', '.js', '.md', '.markdown' ]
      supported_extensions.include?(File.extname(file))
    end

    def display_error(message)
      if RUBY_VERSION.to_f > 1.8 then
        puts "(\u{256F}\u{00B0}\u{25A1}\u{00B0}\u{FF09}\u{256F}".green + "\u{FE35} \u{253B}\u{2501}\u{253B} ".yellow + " Build not complete.".red
      else
        puts "Build not complete.".red
      end
        puts " #{message}"
        exit 1
    end


    def get_file_name(str)
      str = str.gsub(' ', '_').downcase + '.html'
    end


    def get_fh(output_directory, output_file)
      File.open("#{output_directory}/#{output_file}", 'w')
    end
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
