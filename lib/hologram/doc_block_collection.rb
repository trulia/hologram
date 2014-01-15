module Hologram
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
