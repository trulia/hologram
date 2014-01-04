require 'spec_helper'

describe Hologram::DocumentBlock do

  let(:config) do
    { 'name' => 'foo', 'category' => 'bar', 'title' => 'baz', 'parent' => 'pop' }
  end
  let(:markdown){ 'blah' }
  let(:doc_block){ subject.class.new(config, markdown) }

  context '#set_members' do
    it 'sets accessors for the the block config' do
      config.each do |k, v|
        expect(doc_block.send(k)).to eql v
      end
    end
  end

  context '#get_hash' do
    let(:meta) do
      { :name => 'foo', :category => 'bar', :title => 'baz', :parent => 'pop' }
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
    end

    context 'when markdown is not present' do
      let(:invalid_doc_block) do
        subject.class.new(config)
      end

      it 'returns false' do
        expect(invalid_doc_block.is_valid?).to eql false
      end
    end
  end

  context '#markdown_with_heading' do
    it 'returns markdown with a specified header' do
      expect(doc_block.markdown_with_heading(2)).to eql "\n\n<h2 id=\"foo\">baz</h2>blah"
    end
  end
end
