require 'spec_helper'
require 'hologram/block_code_renderer'
require 'haml'

Hologram::CodeExampleRenderer.load_renderers_and_templates

describe Hologram::BlockCodeRenderer do
  describe '#render' do
    let(:formatter) { double(:formatter) }
    let(:lexer) { double(:lexer, lex: lexed_code) }
    let(:lexed_code) { double(:lexed_code) }

    before do
      allow(Rouge::Formatters::HTML).to receive(:new) { formatter }
      allow(formatter).to receive(:format) { formatted_code }
    end

    subject { Hologram::BlockCodeRenderer.new(code, markdown_language).render }

    context 'expected language' do
      before do
        allow(Rouge::Lexer).to receive(:find) { lexer }
      end

      context 'slim' do
        let(:language) { 'slim' }
        let(:code) { 'h1 Markup Example' }
        let(:formatted_code) { 'formatted h1' }

        context 'when the language is a slim_example' do
          let(:markdown_language) { 'slim_example' }

          it 'creates the appropriate lexer' do
            expect(Rouge::Lexer).to receive(:find).with('slim')
            subject
          end

          it { is_expected.to eq [
            "<div class=\"codeExample\">",
              "<div class=\"exampleOutput\">",
                "<h1>Markup Example</h1>",
              "</div>",
              "<div class=\"codeBlock\">",
                "<div class=\"highlight\">",
                  "<pre>",
                    "formatted h1",
                  "</pre>",
                "</div>",
              "</div>",
            "</div>",
          ].join('') }
        end
      end

      context 'haml' do
        let(:language) { 'haml' }
        let(:code) { '%h1 ' }
        let(:formatted_code) { 'formatted h1' }

        context 'when the language is a haml_example' do
          let(:markdown_language) { 'haml_example' }

          it 'creates the appropriate lexer' do
            expect(Rouge::Lexer).to receive(:find).with('haml')
            subject
          end

          it { is_expected.to eq [
            "<div class=\"codeExample\">",
              "<div class=\"exampleOutput\">",
                "<h1></h1>\n",
              "</div>",
              "<div class=\"codeBlock\">",
                "<div class=\"highlight\">",
                  "<pre>",
                    "formatted h1",
                  "</pre>",
                "</div>",
              "</div>",
            "</div>",
          ].join('') }
        end

        context 'when the language is a haml_example_table' do
          let(:markdown_language) { 'haml_example_table' }
          let(:code) { [
            ".spinner-lg",
            "  %i.fa.fa-spin",
            "",
            "%h1 Example"
          ].join("\n") }

          before do
            allow(lexer).to receive(:lex).with(".spinner-lg\n  %i.fa.fa-spin") { "spinner" }
            allow(lexer).to receive(:lex).with("%h1 Example") { "h1" }
            allow(formatter).to receive(:format) do |code|
              "formatted #{code}"
            end
          end

          it 'creates the appropriate lexer' do
            expect(Rouge::Lexer).to receive(:find).with('haml')
            subject
          end

          it { is_expected.to eq [
            "<div class=\"codeTable\">",
              "<table>",
                "<tbody>",
                  "<tr>",
                    "<th>",
                      "<div class=\"exampleOutput\">",
                        "<div class='spinner-lg'>\n",
                        "  <i class='fa fa-spin'></i>\n",
                        "</div>\n",
                      "</div>",
                    "</th>",
                    "<td>",
                      "<div class=\"codeBlock\">",
                        "<div class=\"highlight\">",
                          "<pre>",
                            "formatted spinner",
                            "</pre>",
                        "</div>",
                      "</div>",
                    "</td>",
                  "</tr>",
                  "<tr>",
                    "<th>",
                      "<div class=\"exampleOutput\">",
                        "<h1>Example</h1>\n",
                      "</div>",
                    "</th>",
                    "<td>",
                      "<div class=\"codeBlock\">",
                        "<div class=\"highlight\">",
                          "<pre>",
                            "formatted h1",
                          "</pre>",
                        "</div>",
                      "</div>",
                    "</td>",
                  "</tr>",
                "</tbody>",
              "</table>",
            "</div>"
          ].join('') }
        end
      end

      context 'html' do
        let(:language) { 'html' }
        let(:code) { '<h2></h2>' }
        let(:formatted_code) { 'formatted h2' }

        context 'when the language is html_example' do
          let(:markdown_language) { 'html_example' }

          it 'creates the appropriate lexer' do
            expect(Rouge::Lexer).to receive(:find).with('html')
            subject
          end

          it { is_expected.to eq [
            "<div class=\"codeExample\">",
              "<div class=\"exampleOutput\">",
                "<h2></h2>",
              "</div>",
              "<div class=\"codeBlock\">",
                "<div class=\"highlight\">",
                  "<pre>",
                    "formatted h2",
                  "</pre>",
                "</div>",
              "</div>",
            "</div>",
          ].join('') }
        end

        context 'when the language is a html_example_table' do
          let(:markdown_language) { 'html_example_table' }
          let(:code) { [
            "<div class='spinner-lg'></div>",
            "",
            "<h1>Example</h1>"
          ].join("\n") }

          before do
            allow(lexer).to receive(:lex).with("<div class='spinner-lg'></div>") { "spinner" }
            allow(lexer).to receive(:lex).with("<h1>Example</h1>") { "h1" }
            allow(formatter).to receive(:format) do |code|
              "formatted #{code}"
            end
          end

          it 'creates the appropriate lexer' do
            expect(Rouge::Lexer).to receive(:find).with('html')
            subject
          end

          it { is_expected.to eq [
            "<div class=\"codeTable\">",
              "<table>",
                "<tbody>",
                  "<tr>",
                    "<th>",
                      "<div class=\"exampleOutput\">",
                        "<div class='spinner-lg'></div>",
                      "</div>",
                    "</th>",
                    "<td>",
                      "<div class=\"codeBlock\">",
                        "<div class=\"highlight\">",
                          "<pre>",
                            "formatted spinner",
                          "</pre>",
                        "</div>",
                      "</div>",
                    "</td>",
                  "</tr>",
                  "<tr>",
                    "<th>",
                      "<div class=\"exampleOutput\">",
                        "<h1>Example</h1>",
                      "</div>",
                    "</th>",
                    "<td>",
                      "<div class=\"codeBlock\">",
                        "<div class=\"highlight\">",
                          "<pre>",
                            "formatted h1",
                          "</pre>",
                        "</div>",
                      "</div>",
                    "</td>",
                  "</tr>",
                "</tbody>",
              "</table>",
            "</div>"
          ].join('') }
        end
      end

      context 'js_example' do
        let(:language) { 'js' }
        let(:markdown_language) { 'js_example' }
        let(:code) { '$(document).ready(function() {});' }
        let(:formatted_code) { 'formatted document.ready' }

        it 'creates the appropriate lexer' do
          expect(Rouge::Lexer).to receive(:find).with('js')
          subject
        end

        it "inserts the code into the docs so that it will run and make the example work" do
          expect(subject).to include [
            "<script>",
              "$(document).ready(function() {});",
            "</script>",
          ].join('')
        end

        it { is_expected.to include [
          "<div class=\"codeBlock jsExample\">",
            "<div class=\"highlight\">",
              "<pre>",
                "formatted document.ready",
              "</pre>",
            "</div>",
          "</div>",
        ].join('') }
      end

      context 'jsx_example' do
        let(:language) { 'jsx' }
        let(:markdown_language) { 'jsx_example' }
        let(:code) { '$(document).ready(function () { React.render(<div className="foo"></div>) });' }
        let(:formatted_code) { 'formatted document.ready' }

        it 'creates the appropriate lexer' do
          expect(Rouge::Lexer).to receive(:find).with('html')
          subject
        end

        it "inserts the code into the docs so that it will run and make the example work" do
          expect(subject).to include [
            "<script type='text/jsx'>",
              "$(document).ready(function () { React.render(<div className=\"foo\"></div>) });",
            "</script>",
          ].join('')
        end

        it { is_expected.to include [
          "<div class=\"codeBlock jsExample\">",
            "<div class=\"highlight\">",
              "<pre>",
                "formatted document.ready",
              "</pre>",
            "</div>",
          "</div>",
        ].join('') }
      end
    end

    context 'unexpected language' do
      let(:markdown_language) { 'fortran' }
      let(:code) { 'goto 12' }
      let(:formatted_code) { 'formatted fortran' }

      before do
        allow(Rouge::Lexer).to receive(:find_fancy) { lexer }
      end

      it { is_expected.to eq [
        "<div class=\"codeBlock\">",
          "<div class=\"highlight\">",
            "<pre>",
              "formatted fortran",
            "</pre>",
          "</div>",
        "</div>",
      ].join('') }
    end

    context 'no language' do
      let(:markdown_language) { nil }
      let(:code) { 'unknown code' }
      let(:formatted_code) { 'formatted unknown code' }

      before do
        allow(Rouge::Lexer).to receive(:find_fancy) { lexer }
      end

      it { is_expected.to eq [
        "<div class=\"codeBlock\">",
          "<div class=\"highlight\">",
            "<pre>",
              "formatted unknown code",
            "</pre>",
          "</div>",
        "</div>",
      ].join('') }
    end
  end
end
