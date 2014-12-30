module Hologram
  module CodeExampleRenderer
    class Template < Struct.new(:template_name)
      def template
        File.read(template_filename).gsub(/\n */, '')
      end

      def template_filename
        custom_file_exists? ? custom_file : default_file
      end

      def custom_file_exists?
        !!self.class.path_to_custom_example_templates && File.file?(custom_file)
      end

      def custom_file
        File.join(self.class.path_to_custom_example_templates, "#{template_name}.html.erb")
      end

      def default_file
        File.join(File.dirname(__FILE__), '..', '..', 'template', 'code_example_templates', "#{template_name}.html.erb")
      end

      class << self
        attr_accessor :path_to_custom_example_templates
      end
    end
  end
end
