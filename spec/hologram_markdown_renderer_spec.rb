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

  context 'slim' do
    it 'can render slim' do
      expect(subject.block_code('button.btn button_text', 'slim_example')).to eq \
        '<div class="codeExample">' +
          '<div class="exampleOutput"><button class="btn">button_text</button></div>' +
          '<div class="codeBlock"><div class="highlight"><pre>button.btn button_text</pre></div></div>' +
        '</div>'
    end
  end
end
