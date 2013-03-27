require "hologram/version"

require 'sass'
require 'redcarpet'
require 'yaml'
require 'pygments'
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
    output_file = nil

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
    puts directories

    #skins need the parent component's file
    parent_file = nil

    directories.each do |directory|
      puts directory
      Dir.foreach(directory) do |input_file|
        next unless input_file.end_with?('scss')
        
        file, markdown = process_file("#{base_directory}/#{directory}#{input_file}")

        if not markdown.nil?

          #set correct file for skin classes
          if file.nil? and directory.include?("skin")
            file = parent_file
          else
            parent_file = file
          end

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
    renderer = Redcarpet::Markdown.new(HTMLwithPygments.new(), { :fenced_code_blocks => true })
    pages.each do |file_name, markdown|
      fh = get_fh(output_directory, file_name)
      fh.write(renderer.render(markdown))
      fh.close()
    end
  end




  class HTMLwithPygments < Redcarpet::Render::HTML
    def block_code(code, language)
      return unless language.include?('example')
      code + '<code>' + Pygments.highlight(code) + '</code>'
    end
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
