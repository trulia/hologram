require 'spec_helper'

describe HologramMarkdownRenderer do
  context 'for backwards compatability' do
    it 'is retained' do
      capture(:stdout) {
        class TestFoo < HologramMarkdownRenderer
        end
      }

      expect(TestFoo.ancestors).to include Hologram::MarkdownRenderer
    end
  end
end
