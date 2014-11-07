require 'spec_helper'

describe Hologram::DocBlockCollection do
  let(:comment) do
    <<-comment
/*doc
---
title: Buttons
name: button
category: Base CSS
---

Button styles can be applied to any element. Typically you'll want
to use either a `<button>` or an `<a>` element:

```html_example
  <button class="btn btnDefault">Click</button>
  <a class="btn btnDefault" href="trulia.com">Trulia!</a>
```

If your button is actually a link to another page, please use the
`<a>` element, while if your button performs an action, such as
submitting a form or triggering some javascript event, then use a
`<button>` element.

*/
comment
  end

  let(:collection){ Hologram::DocBlockCollection.new }

  context '#add_doc_block' do
    context 'when the comment is valid' do
      before do
        collection.add_doc_block(comment, 'fake_file.sass')
      end

      it 'adds a doc block to the collection' do
        expect(collection.doc_blocks.size).to eql 1
      end
    end

    context 'when no yaml is provided' do
      before do
        collection.add_doc_block('', 'fake_file.sass')
      end

      it 'does not add a new block' do
        expect(collection.doc_blocks.size).to eql 0
      end
    end

    context 'when the block has the same name as another block in the collection' do
      let(:duplicate_comment) do
        <<-comment
/*doc
---
title: Imposter Buttons
name: button
category: Base CSS
---

Same old stuff
*/
comment
      end

      before do
        collection.add_doc_block(comment, 'fake_file.sass')
      end

      it 'displays a warning' do
        expect(Hologram::DisplayMessage).to receive(:warning)
        collection.add_doc_block(duplicate_comment, 'fake_file.sass')
      end
    end
  end

  context '#create_nested_structure' do
    context 'when the collection has blocks with parents' do
      before do
        collection.add_doc_block(comment, 'fake_file.sass')
        collection.add_doc_block(%q{
          /*doc
          ---
          title: foo
          name: bah
          parent: button
          ---
          some other button style
          */}, 'fake_file.sass')

        collection.create_nested_structure
      end

      it 'removes the child block from the collection level' do
        expect(collection.doc_blocks.size).to eql 1
      end

      it 'nests the doc block as a child of the parent block' do
        expect(collection.doc_blocks['button'].children.size).to eql 1
      end
    end
  end
end
