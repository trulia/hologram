require "hologram/version"

require 'sass'
require 'redcarpet'
require 'yaml'
require 'pygments'
require 'fileutils'
require 'pathname'

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
        file, markdown = process_file("#{directory}#{input_file}")

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

    input_directory = Pathname.new(input_directory).realpath
    output_directory = Pathname.new(output_directory).realpath


    #collect the markdown pages all together by category
    pages = process_dir(input_directory)

    #generate html from markdown
    renderer = Redcarpet::Markdown.new(HTMLwithPygments.new(), { :fenced_code_blocks => true })
    pages.each do |file_name, markdown|
      fh = get_fh(output_directory, file_name)

      if File.exists?("#{input_directory}/header.html")
        fh.write(File.read("#{input_directory}/header.html"))
      end
      
      #generate doc nav html
      fh.write(renderer.render(markdown))
      
      if File.exists?("#{input_directory}/header.html")
        fh.write(File.read("#{input_directory}/footer.html"))
      end

      fh.close()
    end

    if Dir.exists?("#{input_directory}/_static")
      `rm -rf #{output_directory}/static`
      `cp -R #{input_directory}/_static #{output_directory}/static`
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
