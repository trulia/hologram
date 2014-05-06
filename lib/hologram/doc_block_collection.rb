module Hologram
  class DocBlockCollection
    attr_accessor :doc_blocks

    def initialize
      @doc_blocks = {}
    end

    # this should throw an error if we have a match, but no yaml_match
    def add_doc_block(comment_block, file_name)
      doc_block = DocumentBlock.from_comment(comment_block)
      return unless doc_block
      if !doc_block.is_valid?
        skip_block(doc_block, file_name)
        return
      end

      @doc_blocks[doc_block.name] = doc_block
    end

    def create_nested_structure
      blocks_to_remove_from_top_level = []
      @doc_blocks.each do |key, doc_block|
        # don't do anything to top level doc_blocks
        next if !doc_block.parent

        parent = @doc_blocks[doc_block.parent]
        if parent.nil?
          DisplayMessage.warning("Hologram comment refers to parent: #{doc_block.parent}, but no other hologram comment has name: #{doc_block.parent}, skipping." )
        else
          parent.children[doc_block.name] = doc_block
          doc_block.parent = parent

          if doc_block.categories.empty?
            doc_block.categories = parent.categories
          end

          blocks_to_remove_from_top_level << doc_block.name
        end
      end

      blocks_to_remove_from_top_level.each do |key|
        @doc_blocks.delete(key)
      end
    end

    def skip_block(doc_block, file_name)
      DisplayMessage.warning(doc_block.errors.join("\n") << " in #{file_name}. This hologram comment will be skipped.")
    end
  end
end
