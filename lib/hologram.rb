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

require 'hologram_markdown_renderer'

module Hologram
  INIT_TEMPLATE_PATH = File.expand_path('./template/', File.dirname(__FILE__)) + '/'
  INIT_TEMPLATE_FILES = [
    INIT_TEMPLATE_PATH + '/hologram_config.yml',
    INIT_TEMPLATE_PATH + '/doc_assets',
  ]
end
