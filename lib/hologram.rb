require "hologram/version"

# require 'sass'
require 'redcarpet'
require 'yaml'
require 'pygments'
require 'fileutils'
require 'pathname'

class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end

  def pink
    colorize(35)
  end
end

module Hologram
  
  def self.get_code_doc(file)
    
    file = File.read(file)
    comment_match = /^\/\*(.*?)\*\//m.match(file)
    return nil unless comment_match
    comment_block = comment_match[0]
    match = /^---\s(.*?)\s---$/m.match(comment_block)
    return nil unless match
  
    yaml = match[0]
    markdown = comment_block.sub(yaml, '').sub('/*', '').sub('*/', '')

    {config: YAML::load(yaml), markdown: markdown}
  end


  def self.get_file_name(str)
    str = str.gsub(' ', '_').downcase + '.html'
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
      output = "\n\n# #{doc[:config]['title']}"
      #out docs
    else
      output << "\n\n## #{doc[:config]['title']}"
    end
      
    output << doc[:markdown]
    return output_file, output, (doc[:config]['type'] == 'skin')
  end


  def self.process_dir(base_directory)
    pages = {}

    #get all directories in our library folder
    directories = Dir.glob("#{base_directory}/**/*/").sort
    directories.unshift(base_directory)

    #skins need the parent component's file
    parent_file = nil
    last_directory = nil

    directories.each do |directory|
      Dir.foreach(directory) do |input_file|
        
        if is_supported_file_type?(input_file)
          if input_file.end_with?('md')
            pages[File.basename(input_file, '.md') + '.html'] = File.read("#{directory}/#{input_file}")
          else
            file, markdown, skin = process_file("#{directory}/#{input_file}")

            if markdown
              #set correct file for skin classes
              if skin
                file = parent_file
              else
                parent_file = file
              end

              if file.nil?
                raise "Could not save output for " + "#{input_file}".yellow + ", did you intend to set type: component?"
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
    if  !config.key?('source')
      raise "No source directory specified in the config file"
    end

    if  !config.key?('destination')
      raise "No destination directory specified in the config"
    end

    if  !config.key?('documentation_assets')
      raise "No documentation assets directory specified"
    end

    # Create the output directory if it doesn't exist
    unless File.directory?(config['source'])
      FileUtils.mkdir_p(config['source'])
    end

    input_directory  = Pathname.new(config['source']).realpath
    output_directory = Pathname.new(config['destination']).realpath
    doc_assets       = Pathname.new(config['documentation_assets']).realpath

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
      
      # only include the init javascript on the javascript page
      if File.exists?("#{doc_assets}/#{file_name}_footer.html")
        fh.write(File.read("#{doc_assets}/#{file_name}_footer.html"))
      end

      # write the footer
      if File.exists?("#{doc_assets}/footer.html")
        fh.write(File.read("#{doc_assets}/footer.html"))
      end

      fh.close()
    end

    config['additional_assets'].each do |dir|
      dirpath  = Pathname.new(dir).realpath
      if Dir.exists?("#{dir}")
        `rm -rf #{output_directory}/#{dirpath.basename}`
        `cp -R #{dirpath} #{output_directory}/#{dirpath.basename}`
      end
    end

    Dir.foreach(doc_assets) do |file|
      if file.start_with?('_')
        `rm -rf #{output_directory}/#{file.sub('_', '')}`
        `cp -R #{doc_assets}/#{file} #{output_directory}/#{file.sub('_', '')}`
      end
    end

  end


  def self.init(args)
    begin 
      config = args ? YAML::load_file(args[0]) : YAML::load_file('hologram_config.yml')
      current_path = Dir.pwd
      base_path = Pathname.new(args[0])
      Dir.chdir(base_path.dirname)
      self.build(config)
      Dir.chdir(current_path)
      puts "Build successful. (-: ".green
    rescue Errno::ENOENT
      puts "(\u{256F}\u{00B0}\u{25A1}\u{00B0}\u{FF09}\u{256F}".green + "\u{FE35} \u{253B}\u{2501}\u{253B} ".yellow + " Build not complete.".red 
      puts " Could not load config file."
    rescue RuntimeError => e
      puts "(\u{256F}\u{00B0}\u{25A1}\u{00B0}\u{FF09}\u{256F}".green + "\u{FE35} \u{253B}\u{2501}\u{253B} ".yellow + " Build not complete.".red 
      puts " #{e}"
    end
  end


  def self.is_supported_file_type?(file)
    supported_extensions = ['.scss', '.js', '.md', '.markdown' ]
    supported_extensions.include?(File.extname(file))
  end


  #This needs to be a runtime config that can be passed in to hologram
  #instead of being part of it. This should get moved to the oocss docs
  #in that case
  class TruliaMarkdown < Redcarpet::Render::HTML
    def block_code(code, language)
      if language and language.include?('example')
        if language.include?('js')
          '<script>' + code + '</script><div class="codeBlock">' + Pygments.highlight(code) + '</div>'
        else
          '<div class="codeExample">' + '<div class="exampleOutput">' + code + '</div>' + '<div class="codeBlock">' + Pygments.highlight(code) + '</div>' + '</div>'
        end
      else
        '<div class="codeBlock">' + Pygments.highlight(code) + '</div>'
      end      
    end

    def table(heading, body)
      return '<table class="table tableBasic"><thead>' + heading + '</thead><tbody>' + body + '</tbody></table>'
    end

    def table_row(content)
      '<tr>' + content.gsub('<th>', '<th class="txtL">') + '</tr>'
    end

    def list(contents, list_type)
      if list_type.to_s.eql?("ordered")
        '<ol class="listOrdered">' + contents + '</ol>'
      else
        '<li class="listBulleted">' + contents + '</li>'
      end
    end
  end

end
