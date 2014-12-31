require 'spec_helper'

Hologram::CodeExampleRenderer.load_renderers_and_templates

describe Hologram::CodeExampleRenderer::Factory do
  describe '.define' do
    let(:example_type) { 'foobar' }

    before do
      allow(Hologram::CodeExampleRenderer::Template).to receive(:new).with('custom_example_template') { double(template: 'the full custom example template') }
      allow(Hologram::CodeExampleRenderer::Template).to receive(:new).with('custom_table_template') { double(template: 'the full custom table template') }
      allow(Hologram::CodeExampleRenderer::Template).to receive(:new).with(nil).and_call_original
    end

    context "when a renderer is registered with all of the options" do
      before do
        custom_lexer = double(:lexer, lex: 'lexed code from supplied lexer')

        Hologram::CodeExampleRenderer::Factory.define(example_type) do
          example_template 'custom_example_template'
          table_template 'custom_table_template'
          lexer { custom_lexer }
          rendered_example { |code| "special rendering for #{code}" }
        end
      end

      after { Hologram::CodeExampleRenderer.unregister(example_type) }

      describe "the registered example class" do
        let(:example_class) { Hologram::CodeExampleRenderer.example_class_for(example_type) }
        let(:example) { example_class.new('some code') }

        it "renders the example using the block supplied to the factory" do
          expect(example.rendered_example).to eq "special rendering for some code"
        end

        it "formats the code uses the supplied lexer" do
          formatter = double(:formatter)
          allow(Rouge::Formatters::HTML).to receive(:new) { formatter }

          expect(formatter).to receive(:format).with('lexed code from supplied lexer') { 'formatted code' }
          example.code_example
        end
      end

      describe "the registered templates" do
        let(:example_template) { Hologram::CodeExampleRenderer.example_template_for(example_type) }
        let(:table_template) { Hologram::CodeExampleRenderer.table_template_for(example_type) }

        it "uses the supplied example template" do
          expect(example_template).to eq 'the full custom example template'
        end

        it "uses the supplied table template" do
          expect(table_template).to eq 'the full custom table template'
        end
      end
    end

    context "when a renderer is registered with only some of the options" do
      before do

        Hologram::CodeExampleRenderer::Factory.define(example_type) do
          example_template 'custom_example_template'
        end
      end

      after { Hologram::CodeExampleRenderer.unregister(example_type) }

      describe "the registered example class" do
        let(:example_class) { Hologram::CodeExampleRenderer.example_class_for(example_type) }
        let(:example) { example_class.new('some code') }

        it "renders the example as is" do
          expect(example.rendered_example).to eq "some code"
        end

        it "formats the code uses the default lexer" do
          formatter = double(:formatter)
          allow(Rouge::Lexer).to receive(:find_fancy).with('guess', 'some code') { double(lex: 'default lexed code') }
          allow(Rouge::Formatters::HTML).to receive(:new) { formatter }

          expect(formatter).to receive(:format).with('default lexed code') { 'formatted code' }
          example.code_example
        end
      end

      describe "the registered templates" do
        let(:example_template) { Hologram::CodeExampleRenderer.example_template_for(example_type) }
        let(:table_template) { Hologram::CodeExampleRenderer.table_template_for(example_type) }

        it "uses the supplied example template" do
          expect(example_template).to eq 'the full custom example template'
        end

        it "does not have a table template" do
          expect(table_template).to be_nil
        end
      end
    end
  end
end
