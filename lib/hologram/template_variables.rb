module Hologram

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
end
