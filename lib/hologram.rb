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
require 'hologram/display_message'
require 'hologram/errors'
require 'hologram/utils'
require 'hologram/markdown_renderer'

module Hologram
  INIT_TEMPLATE_PATH = File.expand_path('./template/', File.dirname(__FILE__)) + '/'
  INIT_TEMPLATE_FILES = [
    INIT_TEMPLATE_PATH + '/hologram_config.yml',
    INIT_TEMPLATE_PATH + '/doc_assets',
  ]
end

class HologramMarkdownRenderer < Hologram::MarkdownRenderer
  def self.inherited(subclass)
    puts "HologramMarkdownRenderer is deprecated, please inherit from Hologram::MarkdownRenderer"
  end
end
