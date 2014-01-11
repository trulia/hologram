require 'redcarpet'
require 'yaml'
require 'pygments'
require 'fileutils'
require 'pathname'
require 'erb'

require 'hologram/version'
require 'hologram/document_block'
require 'hologram/doc_block_collection'
require 'hologram/doc_parser'
require 'hologram/doc_builder'
require 'hologram/template_variables'

require 'hologram_markdown_renderer'

module Hologram
  INIT_TEMPLATE_PATH = File.expand_path('./template/', File.dirname(__FILE__)) + '/'
  INIT_TEMPLATE_FILES = [
    INIT_TEMPLATE_PATH + '/hologram_config.yml',
    INIT_TEMPLATE_PATH + '/doc_assets',
  ]
end

class DisplayMessage
  def self.error(message)
    if RUBY_VERSION.to_f > 1.8 then
      puts "(\u{256F}\u{00B0}\u{25A1}\u{00B0}\u{FF09}\u{256F}".green + "\u{FE35} \u{253B}\u{2501}\u{253B} ".yellow + " Build not complete.".red
    else
      puts "Build not complete.".red
    end
      puts " #{message}"
      exit 1
  end

  def self.warning(message)
    puts "Warning: ".yellow + message
  end
end


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
