require "hologram/version"

require 'sass'
require 'redcarpet'
require 'yaml'

require 'fileutils'

module Hologram
  def self.get_scss_code_doc(file)
    node = Sass::Engine.for_file(file, {}).to_tree().children[0]

    return nil unless node.instance_of? Sass::Tree::CommentNode

    raw_text = node.value.first
    yaml = /^---[,-:\d\w\s]*---$/.match(raw_text)[0]
    markdown = raw_text.sub(yaml, '').sub('/*', '').sub('*/', '')
    
    return {config: YAML::load(yaml), markdown: markdown}
  end


  def self.get_code_doc(file_name)
    #find if there is a comment block in the file
    #pull out yaml
    #pull out markdown
    get_scss_code_doc(file_name)
    #return yaml, markdown
  end

  def self.get_file_name(str)
    str.gsub!(' ', '_').downcase! + '.html'
  end

  def self.get_fh(output_directory, output_file)
    FileUtils.mkdir_p(output_directory)
    File.open("#{output_directory}/#{output_file}", 'w')
  end

  def self.process_file(file)
    doc = get_code_doc(file)
    return  nil, nil if doc.nil?
    output = ""

    if (doc[:config]["type"] == 'component')
      output_file = get_file_name(doc[:config]['category'])

      #out anchor/heading
      output = "# #{doc[:config]['title']}"
      #out docs
    else
      output << "## #{doc[:config]['title']}"
    end
      
    output << doc[:markdown]
    return output_file, output
  end

  def self.process_dir(base_directory)
    pages = {}

    #get all directories in our library folder
    directories = Dir.glob("#{base_directory}/**/*/") 
    print directories

    directories.each do |directory|
      Dir.foreach(directory) do |file|
        next unless file.end_with?('scss')
        file, markdown = process_file("#{base_directory}/#{directory}#{file}")

        if not file.nil?
          pages[file] = "" if pages[file].nil?
          pages[file] << markdown
        end

      end
    end

    return pages
  end
  def self.build(input_directory, output_directory)

    #collect the markdown pages all together by category
    pages = process_dir(input_directory)

    #generate html from markdown
    renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(), {})
    pages.each do |file_name, markdown|
      fh = get_fh(output_directory, file_name)
      #write header.html
      #generate doc nav html
      fh.write(renderer.render(markdown))
      #footer.html
      fh.close()
    end

      #
  end
  # Your code goes here...
  # parse a sass file
  #  - get yaml config
  #  - find any markdown
  # parse skin files
  # table doc output
  # add markdown doc to output for component
  # add markdown doc to output for skins
  #
  # initialize markdown engine setup the custom same time
end
