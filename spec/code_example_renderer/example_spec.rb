require 'spec_helper'

describe Hologram::CodeExampleRenderer::Example do
  let(:code) { 'goto 12' }
  let(:example) { described_class.new(code) }

  describe '#rendered_example' do
    subject { example.rendered_example }
    it { is_expected.to eq 'goto 12' }
  end

  describe '#code_example' do
    let(:formatter) { double(:formatter) }
    let(:lexer) { double(:lexer, lex: 'lexed_code') }

    before do
      allow(Rouge::Lexer).to receive(:find_fancy).with('guess', code) { lexer }
      allow(Rouge::Formatters::HTML).to receive(:new) { formatter }
      allow(formatter).to receive(:format).with('lexed_code') { 'formatted_lexed_code' }
    end

    subject { example.code_example }

    it { is_expected.to eq 'formatted_lexed_code' }
  end
end
