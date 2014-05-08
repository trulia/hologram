module Hologram

  #Helper class for binding things for ERB
  class TemplateVariables
    attr_accessor :title, :file_name, :blocks, :output_files_by_category, :config, :pages

    def initialize(args)
      set_args(args)
    end

    def set_args(args)
      args.each do |k,v|
        instance_variable_set("@#{k}", v) unless v.nil?
      end
    end

    def get_binding
      binding()
    end
  end
end
