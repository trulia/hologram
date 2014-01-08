require 'spec_helper'

describe Hologram::DocParser do

  let(:doc) do
<<-eos
/*doc
---
title: Some other style
name: otherStyle
category: Foo
---
Markdown stuff
*/
eos
  end

  let(:child_doc) do
<<-eos
/*doc
---
parent: button
name: otherStyle
title: Some other style
---
Markdown stuff
*/
eos
  end

  let(:source_path) { 'spec/fixtures/source' }
  let(:temp_doc) { File.join(source_path, 'components', 'button', 'skin', 'testSkin.css') }

  subject(:parser) { Hologram::DocParser.new('spec/fixtures/source') }

  context '#parse' do
    let(:result) { parser.parse }

    it 'builds and returns a hash of pages' do
      expect(result).to be_a Hash
    end

    context 'when an index page is specified' do
      subject(:parser) { Hologram::DocParser.new('spec/fixtures/source', 'foo') }

      around do |example|
        File.open(temp_doc, 'a+'){ |io| io << doc }
        example.run
        FileUtils.rm(temp_doc)
      end

      it 'uses that page as the index' do
        expect(result['index.html'][:md]).to include 'Markdown stuff'
      end
    end

    context 'when the source is a parent doc' do
      around do |example|
        File.open(temp_doc, 'a+'){ |io| io << doc }
        example.run
        FileUtils.rm(temp_doc)
      end

      it 'takes the category in a collection and treats them as the page names' do
        expect(result.keys).to include 'foo.html'
      end
    end

    context 'when a source doc is a child' do
      around do |example|
        File.open(temp_doc, 'a+'){ |io| io << child_doc }
        example.run
        FileUtils.rm(temp_doc)
      end

      before do
        parser.parse
      end

      it 'appends the child doc to the category page' do
        expect(result['base_css.html'][:md]).to include 'Some other style'
      end

      it 'assigns the child doc a deeper header' do
        expect(result['base_css.html'][:md]).to include '<h2 id="otherStyle">Some other style</h2>'
      end
    end
  end
end
