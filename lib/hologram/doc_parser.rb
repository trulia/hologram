module Hologram
  class DocParser
    SUPPORTED_EXTENSIONS = ['.css', '.scss', '.less', '.sass', '.styl', '.js', '.md', '.markdown' ]
    attr_accessor :source_path, :pages, :doc_blocks

    def initialize(source_path, index_name = nil)
      @source_path = source_path
      @index_name = index_name
      @pages = {}
      @categories = {}
    end

    def parse
      # recursively traverse our directory structure looking for files that
      # match our "parseable" file types. Open those files pulling out any
      # comments matching the hologram doc style /*doc */ and create DocBlock
      # objects from those comments, then add those to a collection object which
      # is then returned.
      doc_block_collection = process_dir(source_path)

      # doc blocks can define parent/child relationships that will nest their
      # documentation appropriately. we can't put everything into that structure
      # on our first pass through because there is no guarantee we'll parse files
      # in the correct order. This step takes the full collection and creates the
      # proper structure.
      doc_block_collection.create_nested_structure


      # hand off our properly nested collection to the output generator
      build_output(doc_block_collection.doc_blocks)

      # if we have an index category defined in our config copy that
      # page to index.html
      if @index_name
        name = @index_name + '.html'
        if @pages.has_key?(name)
          @pages['index.html'] = @pages[name]
        end
      end

      return @pages, @categories
    end

    private

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

    def build_output(doc_blocks, output_file = nil, depth = 1)
      doc_blocks.sort.map do |key, doc_block|

        # if the doc_block has a category set then use that, this will be
        # true of all top level doc_blocks. The output file they set will then
        # be passed into the recursive call for adding children to the output
        if doc_block.category
          output_file = get_file_name(doc_block.category)
          @categories[doc_block.category] = {:file_name => output_file}
        end

        if !@pages.has_key?(output_file)
          @pages[output_file] = {:md => "", :blocks => []}
        end

        @pages[output_file][:blocks].push(doc_block.get_hash)
        @pages[output_file][:md] << doc_block.markdown_with_heading(depth)

        if doc_block.children
          depth += 1
          build_output(doc_block.children, output_file, depth)
          depth -= 1
        end
      end
    end

    def is_supported_file_type?(file)
      SUPPORTED_EXTENSIONS.include?(File.extname(file))
    end

    def get_file_name(str)
      str = str.gsub(' ', '_').downcase + '.html'
    end
  end
end
