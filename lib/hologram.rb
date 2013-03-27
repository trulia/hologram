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
    match = /^---[<>@,-:\d\w\s]*---$/.match(raw_text)

    return nil unless match

    yaml = match[0] 

    markdown = raw_text.sub(yaml, '').sub('/*', '').sub('*/', '')
    
    return {config: YAML::load(yaml), markdown: markdown}
  end

  # This can turn into a more generic switch method for supporting multiple types of doc files
  # TODO add js as a file type
  def self.get_code_doc(file_name)
    case File.extname(file_name)
    when '.scss'
    get_scss_code_doc(file_name)
    when '.js'
      #TODO
    end
  end

  def self.get_file_name(str)
    str.gsub!(' ', '_').downcase! + '.html'
  end


  def self.get_fh(output_directory, output_file)
    File.open("#{output_directory}/#{output_file}", 'w')
  end


  def self.process_file(file)
    doc = get_code_doc(file)
    return if doc.nil?

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
    return output_file, output, (doc[:config]['type'] == 'skin')
  end


  def self.process_dir(base_directory)
    pages = {}

    #get all directories in our library folder
    directories = Dir.glob("#{base_directory}/**/*/")
    directories.unshift(base_directory)

    #skins need the parent component's file
    parent_file = nil

    directories.each do |directory|
      Dir.foreach(directory) do |input_file|

        if is_supported_file_type?(input_file)
          if input_file.end_with?('md')
            pages[File.basename(input_file, '.md') + '.html'] = File.read("#{directory}/#{input_file}")
          else
            file, markdown, skin = process_file("#{directory}/#{input_file}")

            if not markdown.nil?

              #set correct file for skin classes
              if skin
                file = parent_file
              else
                parent_file = file
              end

              pages[file] = "" if pages[file].nil?
              pages[file] << markdown
            end
          end
        end
      end
    end

    return pages
  end


  def self.build(config)

    # Create the output directory if it doesn't exist
    unless File.directory?(config['output_directory'])
      FileUtils.mkdir_p(config['output_directory'])
    end

    input_directory  = Pathname.new(config['source_directory']).realpath
    output_directory = Pathname.new(config['output_directory']).realpath
    doc_assets       = Pathname.new(config['doc_assets']).realpath
    static_assets    = Pathname.new(config['static_assets']).realpath

    #collect the markdown pages all together by category
    pages = process_dir(input_directory)

    #generate html from markdown
    renderer = Redcarpet::Markdown.new(TruliaMarkdown, { :fenced_code_blocks => true, :tables => true })
    pages.each do |file_name, markdown|
      fh = get_fh(output_directory, file_name)

      # generate doc nav html
      if File.exists?("#{doc_assets}/header.html")
        fh.write(File.read("#{doc_assets}/header.html"))
      end
      
      # write the docs
      fh.write(renderer.render(markdown))
      
      # write the footer
      if File.exists?("#{doc_assets}/footer.html")
        fh.write(File.read("#{doc_assets}/footer.html"))
      end

      fh.close()
    end

    if Dir.exists?("#{static_assets}")
      `rm -rf #{output_directory}/#{static_assets.basename}`
      `cp -R #{static_assets} #{output_directory}/#{static_assets.basename}`
    end

    Dir.foreach(doc_assets) do |file|
      if file.start_with?('_')
        `rm -rf #{output_directory}/#{file.sub('_', '')}`
        `cp -R #{doc_assets}/#{file} #{output_directory}/#{file.sub('_', '')}`
      end
    end

  end

  def self.init(args)
    config = args ? YAML::load_file(args[0]) : YAML::load_file('hologram_config.yml')
    current_path = Dir.pwd
    base_path = Pathname.new(args[0])
    Dir.chdir(base_path.dirname)
    self.build(config)
    Dir.chdir(current_path)
  end



  def self.is_supported_file_type?(file)
    supported_extensions = ['.scss', '.js', '.md', '.markdown' ]
    supported_extensions.include?(File.extname(file))
  end



  class TruliaMarkdown < Redcarpet::Render::HTML
    def block_code(code, language)
      return unless language.include?('example')
      '<div class="codeExample">' + '<div class="exampleOutput">' + code + '</div>' + '<div class="codeBlock">' + Pygments.highlight(code) + '</div>' + '</div>'
    end

    def table(heading, body)
      return '<table class="table simpleTable"><thead>' + heading + '</thead><tbody>' + body + '</tbody></table>'
    end

    def table_row(content)
      '<tr>' + content.gsub('<th>', '<th class="txtL">') + '</tr>'
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
