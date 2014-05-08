require 'spec_helper'

describe Hologram::DocumentBlock do

  let(:config) do
    { 'name' => 'foo', 'category' => 'bar', 'title' => 'baz', 'parent' => 'pop' }
  end
  let(:markdown){ 'blah' }
  let(:doc_block){ subject.class.new(config, markdown) }

  context '.from_comment' do
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

    let(:bad_doc) do
<<-eos
/*doc
---
: :
---
Markdown stuff
*/
eos
    end

    it 'initializes a new document block from a matching comment' do
      doc_block = Hologram::DocumentBlock.from_comment(doc)
      expect(doc_block).to be_a Hologram::DocumentBlock
    end

    it 'raises CommentLoadError when the yaml section is bad' do
      expect{
        Hologram::DocumentBlock.from_comment(bad_doc)
      }.to raise_error Hologram::CommentLoadError
    end

    it 'returns nothing if its not a valid doc block' do
      doc_block = Hologram::DocumentBlock.from_comment('foo')
      expect(doc_block).to be_nil
    end

    it 'sets up the usual attrs using the YAML and markdown text' do
      doc_block = Hologram::DocumentBlock.from_comment(doc)
      expect(doc_block.name).to eql 'otherStyle'
      expect(doc_block.categories).to eql ['Foo']
      expect(doc_block.title).to eql 'Some other style'
      expect(doc_block.markdown).to eql "/*doc\n\nMarkdown stuff\n*/\n"
    end
  end

  context '#set_members' do
    it 'sets accessors for the the block config' do
      expect(doc_block.send('name')).to eql 'foo'
      expect(doc_block.send('categories')).to eql ['bar']
      expect(doc_block.send('title')).to eql 'baz'
      expect(doc_block.send('parent')).to eql 'pop'
    end
  end

  context '#get_hash' do
    let(:meta) do
      { :name => 'foo', :categories => ['bar'], :title => 'baz', :parent => 'pop' }
    end

    it 'returns a hash of meta info' do
      expect(doc_block.get_hash).to eql meta
    end
  end

  context '#is_valid?' do
    context 'when name and markdown is present' do
      it 'returns true' do
        expect(doc_block.is_valid?).to eql true
      end
    end

    context 'when name is not present' do
      let(:invalid_doc_block) do
        subject.class.new(config.merge(:name => nil))
      end

      it 'returns false' do
        expect(invalid_doc_block.is_valid?).to eql false
      end

      it 'populates errors' do
        invalid_doc_block.is_valid?
        expect(invalid_doc_block.errors).to include('Missing name or title config value')
      end
    end

    context 'when markdown is not present' do
      let(:invalid_doc_block) do
        subject.class.new(config)
      end

      it 'returns false' do
        expect(invalid_doc_block.is_valid?).to eql false
      end

      it 'populates errors' do
        invalid_doc_block.is_valid?
        expect(invalid_doc_block.errors).to include('Missing required markdown')
      end
    end
  end

  context '#markdown_with_heading' do
    it 'returns markdown with a specified header' do
      expect(doc_block.markdown_with_heading(2)).to eql "\n\n<h2 id=\"foo\">baz</h2>blah"
    end
  end
end
