# Hologram

Hologram is style guide and code documentation build system. It uses
yaml and markdown inside comment blocks in your code to allow easy
updating and something. When combined with OOCSS it makes it so that
maintaining documentation and updating css can all be done in a single
file in a logical and clear manner.

## Installation

Add this line to your application's Gemfile:

    gem 'hologram', :git => 'https://github.com/trulia/hologram.git'

And then execute:

    $ bundle

## Usage

###Documenting your styles

Hologram looks in each css/scss/sass file for a comment at the beginning
of the file with the following format:

    /*
    ---
    title: Buttons
    name: button
    category: Base CSS
    author: Derek Reynolds <dreynolds@trulia.com>
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

The first section of the comment is a yaml block that defines certain
aspects of the this documentation block. The second part is simply
markdown as defined by Redcarpet.

###Document YAML section
The yaml in the doc block can have any key value pair you deem important
but it specifically looks for the following keys:

* **title**: The title to display in the documents
* **category**: This is the broad category for the component, all
  components in the same category will be displayed on a single page in
  Hologram's output.
* **name**: This is used for grouping components, by assigning
  a name a component can be referenced in another component as a parent.
* **parent**: Optional. If this is set the current component will be
  displayed as a section within the parent's documentation.

Hologram needs a few configuration settings before it can begin to build
your documentation for you. This config file is a yaml file with the
following key values:

* **source**: relative path to your source files
* **destination**: relative path to where you want the documentation to be
  built to
* **documentation_assets**: The path that contains supporting assets for
  the documentaiton page. This typically includes html fragments,
  css, javascript and any images.
* **custom_markdown**: This is the filename of a class that extends
  RedCarpet::Render::HTML class. Use this for when you need
  additional classes or html tags for different parts of the page.
* **dependencies**: This is a list of folders to be copied into the
  destination folder. Typically this will be where your style
  guide's css is built in to.

###Documentation Assets

Typically you'll want to have your own header and footer. T

TBD




## Contributing

TBD

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
