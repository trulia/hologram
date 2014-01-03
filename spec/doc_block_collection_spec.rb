require 'spec_helper'

describe Hologram::DocBlockCollection do
  let(:comment) do
   comment = <<comment
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
        collection.add_doc_block(comment)
      end

      it 'adds a doc block to the collection' do
        expect(collection.doc_blocks.size).to eql 1
      end
    end

    context 'when no yaml is provided' do
      before do
        collection.add_doc_block('')
      end

      it 'does not add a new block' do
        expect(collection.doc_blocks.size).to eql 0
      end
    end
  end

  context '#create_nested_structure' do
    context 'when the collection has blocks with parents' do
      before do
        collection.add_doc_block(comment)
        collection.add_doc_block(%q{
          /*doc
          ---
          title: foo
          name: bah
          parent: button
          ---
          some other button style
          */})

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
