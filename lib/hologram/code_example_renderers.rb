module Hologram
  module CodeExampleRenderers
  end
end

Dir[File.join(File.dirname(__FILE__), 'code_example_renderers', '*')].each do |file|
  require file
end
