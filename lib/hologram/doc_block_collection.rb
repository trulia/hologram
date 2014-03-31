module Hologram
  class DocBlockCollection
    attr_accessor :doc_blocks

    def initialize
      @doc_blocks = {}
    end

    # this should throw an error if we have a match, but no yaml_match
    def add_doc_block(comment_block)
      doc_block = DocumentBlock.from_comment(comment_block)
      return unless doc_block
      skip_block and return if !doc_block.is_valid?

      @doc_blocks[doc_block.name] = doc_block
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

    private

    def skip_block
      DisplayMessage.warning(doc_block.errors.join("\n") << "This hologram comment will be skipped.")
    end
  end
end
