require 'spec_helper'
require 'hologram/block_code_renderer'
require 'haml'
require 'securerandom'

Hologram::CodeExampleRenderer.load_renderers_and_templates

describe Hologram::BlockCodeRenderer do
  describe '#render' do
    subject { Hologram::BlockCodeRenderer.new(code, markdown_language).render.strip }

    context 'expected language' do
      context 'react' do
        let(:language) { 'react' }
        let(:code) { '<ReactExample property="value">Example</ReactExample>' }

        context 'when the language is a react_example' do
          let(:markdown_language) { 'react_example' }
          let(:div_id) { 'randomId' }

          before :each do
            SecureRandom.stub('hex').and_return(div_id);
          end

          it { is_expected.to eq [
            "<div class=\"codeExample\">",
            "  <div class=\"exampleOutput\">",
            "    <div id=\"#{div_id}\"></div>",
            "<script type=\"text/babel\">",
            "  ReactDOM.render(",
            "    <ReactExample property=\"value\">Example</ReactExample>,",
            "    document.getElementById('#{div_id}')",
            "  );",
            "</script>",
            "  </div>",
            "  <div class=\"codeBlock\">",
            "    <div class=\"highlight\">",
            "      <pre><span class=\"nt\">&lt;ReactExample</span> <span class=\"na\">property=</span><span class=\"s\">\"value\"</span><span class=\"nt\">&gt;</span>Example<span class=\"nt\">&lt;/ReactExample&gt;</span></pre>",
            "    </div>",
            "  </div>",
            "</div>"
          ].join("\n") }
        end
      end

      context 'slim' do
        let(:language) { 'slim' }
        let(:code) { 'h1 Markup Example' }

        context 'when the language is a slim_example' do
          let(:markdown_language) { 'slim_example' }

          it { is_expected.to eq [
            "<div class=\"codeExample\">",
            "  <div class=\"exampleOutput\">",
            "    <h1>Markup Example</h1>",
            "  </div>",
            "  <div class=\"codeBlock\">",
            "    <div class=\"highlight\">",
            "      <pre><span class=\"nt\">h1</span><span class=\"w\"> </span>Markup<span class=\"w\"> </span>Example</pre>",
            "    </div>",
            "  </div>",
            "</div>",
          ].join("\n") }
        end
      end

      context 'haml' do
        let(:language) { 'haml' }
        let(:code) { '%h1 Example' }

        context 'when the language is a haml_example' do
          let(:markdown_language) { 'haml_example' }

          it { is_expected.to eq [
            "<div class=\"codeExample\">",
            "  <div class=\"exampleOutput\">",
            "    <h1>Example</h1>\n",
            "  </div>",
            "  <div class=\"codeBlock\">",
            "    <div class=\"highlight\">",
            "      <pre><span class=\"nt\">%h1</span> Example</pre>",
            "    </div>",
            "  </div>",
            "</div>",
          ].join("\n") }
        end

        context 'when the language is a haml_example_table' do
          let(:markdown_language) { 'haml_example_table' }
          let(:code) { [
            ".spinner-lg",
            "  %i.fa.fa-spin",
            "",
            "%h1 Example"
          ].join("\n") }

          it { is_expected.to eq [
            "<div class=\"codeTable\">",
            "  <table>",
            "    <tbody>",
            "      ",
            "        <tr>",
            "          <th>",
            "            <div class=\"exampleOutput\">",
            "              <div class='spinner-lg'>",
            "  <i class='fa fa-spin'></i>",
            "</div>",
            "",
            "            </div>",
            "          </th>",
            "          <td>",
            "            <div class=\"codeBlock\">",
            "              <div class=\"highlight\">",
            "                <pre><span class=\"nc\">.spinner-lg</span>",
            "  <span class=\"nt\">%i</span><span class=\"nc\">.fa.fa-spin</span></pre>",
            "              </div>",
            "            </div>",
            "          </td>",
            "        </tr>",
            "      ",
            "        <tr>",
            "          <th>",
            "            <div class=\"exampleOutput\">",
            "              <h1>Example</h1>",
            "",
            "            </div>",
            "          </th>",
            "          <td>",
            "            <div class=\"codeBlock\">",
            "              <div class=\"highlight\">",
            "                <pre><span class=\"nt\">%h1</span> Example</pre>",
            "              </div>",
            "            </div>",
            "          </td>",
            "        </tr>",
            "      ",
            "    </tbody>",
            "  </table>",
            "</div>"
          ].join("\n") }
        end
      end

      context 'html' do
        let(:language) { 'html' }
        let(:code) { '<h2></h2>' }
        let(:formatted_code) { 'formatted h2' }
        context 'when the language is html_example' do
          let(:markdown_language) { 'html_example' }

          it { is_expected.to eq [
            "<div class=\"codeExample\">",
            "  <div class=\"exampleOutput\">",
            "    <h2></h2>",
            "  </div>",
            "  <div class=\"codeBlock\">",
            "    <div class=\"highlight\">",
            "      <pre><span class=\"nt\">&lt;h2&gt;&lt;/h2&gt;</span></pre>",
            "    </div>",
            "  </div>",
            "</div>",
          ].join("\n") }
        end

        context 'when the language is a html_example_table' do
          let(:markdown_language) { 'html_example_table' }
          let(:code) { [
            "<div class='spinner-lg'></div>",
            "",
            "<h1>Example</h1>"
          ].join("\n") }

          it { is_expected.to eq [
            "<div class=\"codeTable\">",
            "  <table>",
            "    <tbody>",
            "      ",
            "        <tr>",
            "          <th>",
            "            <div class=\"exampleOutput\">",
            "              <div class='spinner-lg'></div>",
            "            </div>",
            "          </th>",
            "          <td>",
            "            <div class=\"codeBlock\">",
            "              <div class=\"highlight\">",
            "                <pre><span class=\"nt\">&lt;div</span> <span class=\"na\">class=</span><span class=\"s\">'spinner-lg'</span><span class=\"nt\">&gt;&lt;/div&gt;</span></pre>",
            "              </div>",
            "            </div>",
            "          </td>",
            "        </tr>",
            "      ",
            "        <tr>",
            "          <th>",
            "            <div class=\"exampleOutput\">",
            "              <h1>Example</h1>",
            "            </div>",
            "          </th>",
            "          <td>",
            "            <div class=\"codeBlock\">",
            "              <div class=\"highlight\">",
            "                <pre><span class=\"nt\">&lt;h1&gt;</span>Example<span class=\"nt\">&lt;/h1&gt;</span></pre>",
            "              </div>",
            "            </div>",
            "          </td>",
            "        </tr>",
            "      ",
            "    </tbody>",
            "  </table>",
            "</div>"
          ].join("\n") }
        end
      end

      context 'js_example' do
        let(:language) { 'js' }
        let(:markdown_language) { 'js_example' }
        let(:code) { '$(document).ready(function() {});' }

        it "inserts the code into the docs so that it will run and make the example work" do
          expect(subject).to include "<script>$(document).ready(function() {});</script>"
        end

        it { is_expected.to include [
          "<div class=\"codeBlock jsExample\">",
          "  <div class=\"highlight\">",
          "    <pre><span class=\"nx\">$</span><span class=\"p\">(</span><span class=\"nb\">document</span><span class=\"p\">).</span><span class=\"nx\">ready</span><span class=\"p\">(</span><span class=\"kd\">function</span><span class=\"p\">()</span> <span class=\"p\">{});</span></pre>",
          "  </div>",
          "</div>",
        ].join("\n") }
      end

      context 'jsx_example' do
        let(:language) { 'jsx' }
        let(:markdown_language) { 'jsx_example' }
        let(:code) { '$(document).ready(function () { React.render(<div className="foo"></div>) });' }

        it "inserts the code into the docs so that it will run and make the example work" do
          expect(subject).to include "<script type='text/babel'>$(document).ready(function () { React.render(<div className=\"foo\"></div>) });</script>"
        end

        it { is_expected.to include [
          "<div class=\"codeBlock jsExample\">",
          "  <div class=\"highlight\">",
          "    <pre>$(document).ready(function () { React.render(<span class=\"nt\">&lt;div</span> <span class=\"na\">className=</span><span class=\"s\">\"foo\"</span><span class=\"nt\">&gt;&lt;/div&gt;</span>) });</pre>",
          "  </div>",
          "</div>",
        ].join("\n") }
      end
    end

    context 'unexpected language' do
      let(:markdown_language) { 'fortran' }
      let(:code) { 'goto 12' }

      it { is_expected.to eq [
        "<div class=\"codeBlock\">",
        "  <div class=\"highlight\">",
        "    <pre>goto 12</pre>",
        "  </div>",
        "</div>",
      ].join("\n") }
    end

    context 'no language' do
      let(:markdown_language) { nil }
      let(:code) { 'unknown code' }

      it { is_expected.to eq [
        "<div class=\"codeBlock\">",
        "  <div class=\"highlight\">",
        "    <pre>unknown code</pre>",
        "  </div>",
        "</div>",
      ].join("\n") }
    end
  end
end
