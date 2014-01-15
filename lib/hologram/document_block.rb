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
end

