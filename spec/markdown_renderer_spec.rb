require 'spec_helper'

describe Hologram::MarkdownRenderer do
  let(:renderer) { described_class.new }

  describe '#postprocess' do
    subject { renderer.postprocess(document) }

    context 'when the document is free of invalid reference links' do
      let(:document) do
        [
          "<p>i'm a <a href='#'>proper reference link</a></p>",
          "<p>i'm similar to an [invalid reference link] [but not quite]</p>",
        ].join("\n")
      end

      it 'does not print a warning' do
        expect(Hologram::DisplayMessage).not_to receive(:warning)
        subject
      end
    end

    context 'when the document contains invalid reference links' do
      let(:document) do
        [
          "<p>hey look at me i'm an [invalid reference link][invalid1]</p>",
          "<p>hey look at me i'm [one as well][invalid2]</p>",
          "<p>why aren't you two <a href='#'>proper reference links?</a></p>",
          "<p>i'm similar to an [invalid reference link] [but not quite]</p>",
        ].join("\n")
      end

      it 'prints a warning for each invalid reference link' do
        expect(Hologram::DisplayMessage).to receive(:warning).twice
        subject
      end
    end
  end
end


