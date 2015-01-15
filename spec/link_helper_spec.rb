require 'spec_helper'
require 'hologram/link_helper'

describe Hologram::LinkHelper do
  let(:pages) do
    [
      {
        name: 'elements.html',
        component_names: [
          'images',
          'buttons',
          'typography',
        ]
      }, {
        name: 'utilities.html',
        component_names: [
          'whitespace',
          'typography'
        ]
      }
    ]
  end

  let(:link_helper) { described_class.new(pages) }

  describe '#link_for' do
    subject { link_helper.link_for(component_name) }

    context 'when the link doesnt belong to any page' do
      let(:component_name) { 'hamburger' }
      it { should be_nil }
    end

    context 'when the link belongs to only one page' do
      let(:component_name) { 'whitespace' }
      it { should == 'utilities.html#whitespace' }
    end

    context 'when the link belongs to more than one page' do
      let(:component_name) { 'typography' }
      it 'creates a link to the first page the component appears on' do
        expect(subject).to eq 'elements.html#typography'
      end
    end
  end

  describe '#all_links' do
    it 'returns a hash from component name to link' do
      expect(link_helper.all_links).to eq ({
        'images' => 'elements.html#images',
        'buttons' => 'elements.html#buttons',
        'typography' => 'elements.html#typography',
        'whitespace' => 'utilities.html#whitespace',
      })
    end
  end
end
