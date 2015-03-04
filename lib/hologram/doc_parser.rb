module Hologram
  class DocParser
    SUPPORTED_EXTENSIONS = ['.css', '.scss', '.less', '.sass', '.styl', '.js', '.md', '.markdown', '.erb' ]
    attr_accessor :source_path, :pages, :doc_blocks, :nav_level

    def initialize(source_path, index_name = nil, plugins=[], opts={})
      @plugins = plugins
      @source_paths = Array(source_path)
      @index_name = index_name
      @nav_level = opts[:nav_level] || 'page'
      @pages = {}
      @output_files_by_category = {}
    end

    def parse
      # recursively traverse our directory structure looking for files that
      # match our "parseable" file types. Open those files pulling out any
      # comments matching the hologram doc style /*doc */ and create DocBlock
      # objects from those comments, then add those to a collection object which
      # is then returned.

      doc_block_collection = DocBlockCollection.new

      @source_paths.each do |source_path|
        process_dir(source_path, doc_block_collection)
      end

      # doc blocks can define parent/child relationships that will nest their
      # documentation appropriately. we can't put everything into that structure
      # on our first pass through because there is no guarantee we'll parse files
      # in the correct order. This step takes the full collection and creates the
      # proper structure.
      doc_block_collection.create_nested_structure


      # hand off our properly nested collection to the output generator
      build_output(doc_block_collection.doc_blocks)

      @plugins.finalize(@pages)

      # if we have an index category defined in our config copy that
      # page to index.html
      if @index_name
        name = @index_name + '.html'
        if @pages.has_key?(name)
          @pages['index.html'] = @pages[name]
        end
      end

      return @pages, @output_files_by_category
    end

    private

    def process_dir(base_directory, doc_block_collection)
      #get all directories in our library folder
      directories = Dir.glob("#{base_directory}/**/*/")
      directories.unshift(base_directory)

      directories.each do |directory|
        # filter and sort the files in our directory
        files = []
        Dir.foreach(directory).select{ |file| is_supported_file_type?("#{directory}/#{file}") }.each do |file|
          files << file
        end
        files.sort!
        process_files(files, directory, doc_block_collection)
      end
    end

    def process_files(files, directory, doc_block_collection)
      files.each do |input_file|
        if input_file.end_with?('md')
          process_markdown_file("#{directory}/#{input_file}", doc_block_collection)
        elsif input_file.end_with?('erb')
          @pages[File.basename(input_file, '.erb')] = {:erb => File.read("#{directory}/#{input_file}")}
        else
          process_file("#{directory}/#{input_file}", doc_block_collection)
        end
      end
    end

    def process_markdown_file(file, doc_block_collection)
      file_str = File.read(file)

      if file_str.match(/^-{3}\n.*hologram:\s*true.*-{3}/m)
        doc_block_collection.add_doc_block(file_str, file)
      else
        @pages[File.basename(file, '.md') + '.html'] = {:md => file_str, :blocks => []}
      end
    end

    def process_file(file, doc_block_collection)
      file_str = File.read(file)
      # get any comment blocks that match the patterns:
      # .sass: //doc (follow by other lines proceeded by a space)
      # other types: /*doc ... */
      if file.end_with?('.sass')
        #For sass strip out leading white spaces after we get the
        #comment, this fixes haml when using this comment style
        hologram_comments = file_str.scan(/\s*\/\/doc\s*((( [^\n]*\n)|\n)+)/).map{ |arr| [arr[0].gsub(/^[ \t]{2}/,'')] }
      else
        hologram_comments = file_str.scan(/^\s*\/\*doc(.*?)\*\//m)

        #check if scss file has sass comments
        if hologram_comments.length == 0 and file.end_with?('.scss')
          hologram_comments = file_str.scan(/\s*\/\/doc\s*((( [^\n]*\n)|\n)+)/).map{ |arr| [arr[0].gsub(/^[ \t]{2}/,'')] }
        end
      end
      return unless hologram_comments



      hologram_comments.each do |comment_block|
        block = doc_block_collection.add_doc_block(comment_block[0], file)

        if (!block.nil?)
          @plugins.block(block, file)
        end

      end
    end

    def build_output(doc_blocks, output_file = nil, depth = 1)
      return if doc_blocks.nil?

      # sort elements in alphabetical order ignoring case
      doc_blocks.sort{|a, b| a[0].downcase<=>b[0].downcase}.map do |key, doc_block|

        #doc_blocks are guaranteed to always have categories (top-level have categories, children get parent categories if empty).
        doc_block.categories.each do |category|
          output_file = get_file_name(category)
          @output_files_by_category[category] = output_file
          add_doc_block_to_page(depth, doc_block, output_file)
        end
        build_output(doc_block.children, nil, depth + 1)
      end

    end

    def is_supported_file_type?(file)
      SUPPORTED_EXTENSIONS.include?(File.extname(file)) and !Dir.exists?(file)
    end

    def get_file_name(str)
      str = str.gsub(' ', '_').downcase + '.html'
    end

    def add_doc_block_to_page(depth, doc_block, output_file)
      if !@pages.has_key?(output_file)
        @pages[output_file] = {:md => "", :blocks => []}
      end


      if (@nav_level == 'section' && depth == 1) || @nav_level == 'all'
        include_sub_nav = true
      else
        include_sub_nav = false
      end

      @pages[output_file][:blocks].push(doc_block.get_hash)
      @pages[output_file][:md] << doc_block.markdown_with_heading(depth, include_sub_nav: include_sub_nav)
    end

  end
end
