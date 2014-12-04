module Hologram
  class LinkHelper
    def initialize(pages)
      @all_links = {}
      pages.each do |page|
        page[:component_names].each do |component_name|
          @all_links[component_name] ||= "/#{page[:name]}\##{component_name}"
        end
      end
    end

    attr_reader :all_links

    def link_for(component_name)
      all_links[component_name]
    end
  end
end
