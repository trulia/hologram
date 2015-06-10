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

  let(:docs_child) do
    <<-eos
/*doc
---
parent: otherStyle
title: Other Style Child
name: otherStyleChild
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

  let(:grandchild_doc) do
    <<-eos
/*doc
---
parent: otherStyle
name: grandbaby
title: Grandbaby
---
Markdown stuff
*/
    eos
  end

  let(:multi_category_child_doc) do
<<-eos
/*doc
---
parent: multi
name: otherStyle
title: MultiChild
---
Markdown stuff
multi-child
*/
eos
  end

  let(:multi_category_doc) do
    <<-eos
/*doc
---
title: MultiParent
name: multi
category: [Foo, Bar]
---
Markdown stuff
multi-parent
*/
    eos
  end

  let(:scss_sass_doc) do
    <<-eos
//doc
//  ---
//  title: sass documentation
//  name: sass_doc
//  category: Foo
//  ---
//
//  Some description
//  on multiple lines
    eos
  end

  let(:source_path) { 'spec/fixtures/source' }
  let(:temp_doc) { File.join(source_path, 'components', 'button', 'skin', 'testSkin.css') }
  let(:scss_temp_doc) { File.join(source_path, 'components', 'button', 'skin', 'scssComponents.scss') }
  let(:plugins) {
    plugins = double()
    allow(plugins).to receive(:block)
    allow(plugins).to receive(:finalize)
    return plugins
  }

  subject(:parser) { Hologram::DocParser.new('spec/fixtures/source/components', nil, plugins) }

  context '#parse' do
    let(:result) { parser.parse }
    let(:pages) { result[0] }
    let(:output_files_by_category) { result[1] }

    it 'builds and returns a hash of pages and a hash of output_files_by_category' do
      expect(pages).to be_a Hash
      expect(output_files_by_category).to be_a Hash
    end

    context 'when the source has multiple paths' do
      subject(:parser) { Hologram::DocParser.new(['spec/fixtures/source/colors', 'spec/fixtures/source/components'], nil, plugins) }

      it 'parses all sources' do
        expect(pages['base_css.html'][:md]).to include 'Base colors'
        expect(pages['base_css.html'][:md]).to include 'Background Colors'
      end
    end

    context 'when the component has two categories' do
      around do |example|
        File.open(temp_doc, 'a+'){ |io| io << multi_category_doc }
        example.run
        FileUtils.rm(temp_doc)
      end

      it 'adds two categories to output_files_by_category' do
        expect(output_files_by_category).to eql({'Foo'=>'foo.html', 'Base CSS'=>'base_css.html', 'Bar'=>'bar.html', 'Code'=>'code.html'})
      end
    end


    context 'when an index page is specified' do
      subject(:parser) { Hologram::DocParser.new('spec/fixtures/source', 'foo', plugins) }

      around do |example|
        File.open(temp_doc, 'a+'){ |io| io << doc }
        example.run
        FileUtils.rm(temp_doc)
      end

      it 'uses that page as the index' do
        expect(pages['index.html'][:md]).to include 'Markdown stuff'
      end
    end

    context 'when the source is a parent doc' do
      around do |example|
        File.open(temp_doc, 'a+'){ |io| io << doc }
        example.run
        FileUtils.rm(temp_doc)
      end

      it 'takes the category in a collection and treats them as the page names' do
        expect(pages.keys).to include 'foo.html'
      end

      context 'when nav_level is set to section' do
        before do
          File.open(temp_doc, 'a+'){ |io| io << docs_child }
          parser.nav_level = 'section'
        end

        it 'generates navigation to children from their parent' do
          parser.parse
          expect(pages['foo.html'][:md]).to include '<li><a href="#otherStyleChild">Other Style Child</a></li>'
        end
      end

      context 'when nav_level is not set' do
        before do
          File.open(temp_doc, 'a+'){ |io| io << docs_child }
          parser.nav_level = nil
        end

        it 'should not generate sub navigation' do
          parser.parse
          expect(pages['foo.html'][:md]).not_to include '<li><a href="#otherStyleChild">Other Style Child</a></li>'
        end
      end
    end

    context 'when a source doc is a child' do
      around do |example|
        File.open(temp_doc, 'a+'){ |io| io << child_doc }
        example.run
        FileUtils.rm(temp_doc)
      end

      it 'appends the child doc to the category page' do
        parser.parse
        expect(pages['base_css.html'][:md]).to include 'Some other style'
      end

      it 'assigns the child doc a deeper header' do
        parser.parse
        expect(pages['base_css.html'][:md]).to include '<h2 id="otherStyle" class="styleguide">Some other style</h2>'
      end

      context 'when nav_level is set to all' do
        before do
          File.open(temp_doc, 'a+'){ |io| io << grandchild_doc }
          parser.nav_level = 'all'
        end

        it 'generates navigation to grandchildren from their parent' do
          parser.parse
          expect(pages['base_css.html'][:md]).to include '<li><a href="#grandbaby">Grandbaby</a></li>'
        end
      end
    end

    context 'when a source doc is the child of a multi category doc block' do
      around do |example|
        File.open(temp_doc, 'w'){ |io|
          io << multi_category_doc
          io << multi_category_child_doc
        }
        example.run
        FileUtils.rm(temp_doc)
      end

      it 'should not output duplicate content' do
        objects = expect(pages['foo.html'][:md]).not_to match(/multi-parent.*multi-child.*multi-child/m)
        objects = expect(pages['bar.html'][:md]).not_to match(/multi-parent.*multi-child.*multi-child/m)
      end

      it 'should correctly order content in each page' do
        objects = expect(pages['foo.html'][:md]).to match(/multi-parent.*multi-child/m)
        objects = expect(pages['bar.html'][:md]).to match(/multi-parent.*multi-child/m)
      end
    end

    context 'when a scss file contains a sass documentation block' do
      around do |example|
        File.open(scss_temp_doc, 'w'){ |io| io << scss_sass_doc }
        example.run
        FileUtils.rm(scss_temp_doc)
      end

      it 'should parse the comment properly' do
        objects = expect(pages['foo.html'][:md]).to include 'Some description'
      end
    end
  end
end
