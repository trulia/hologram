module Hologram
  module CodeExampleRenderer
    class Template < Struct.new(:template_name)
      def template
        return nil if !template_filename
        File.read(template_filename)
      end

      class << self
        attr_accessor :path_to_custom_example_templates
      end

      private

      def template_filename
        return nil if !template_name
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
    end
  end
end
