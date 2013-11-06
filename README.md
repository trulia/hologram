# Hologram

Hologram is a Ruby gem that parses comments in your CSS and helps you turns them into a beautiful style guide.

There are two steps to building a great style guide: 1.) documenting your css and generating html examples, and 2.) actually styling the output of step 1.

The hologram gem itself is only concerned with step 1. This means you are free to make your style guide look however you would like. If you don't feel like going through this process yourself you can take a look at the [templates](https://github.com/trulia/hologram-example/tree/master/templates) in our [example repository](https://github.com/trulia/hologram-example) and use the assets defined there instead.

## Installation

Add this line to your application's Gemfile:

    gem 'hologram'

And then execute:

    $ bundle

If you don't use bundler you can run `gem install hologram`.

## Usage

There are two things you need to do to start using hologram:

1. Create a YAML config file for your project

2. Document yourself some code

### Creating a YAML config file

Hologram needs a few configuration settings before it can begin to build
your documentation for you. Once this is set up you can execute hologram by
simply running:

`hologram path/to/your/config.yml` or (using bundler) `bundle exec hologram path/to/your/config.yml`

Your config file needs to contain the following key/value pairs

* **source**: relative path to your source files

* **destination**: relative path to where you want the documentation to be
  built to

* **documentation_assets**: The path that contains supporting assets for
  the documentaiton page. This typically includes html fragments (header/footer, etc),
  styleguide specific CSS, javascript and any images.

* **custom_markdown**: (optional) this is the filename of a class that extends
  RedCarpet::Render::HTML class. Use this for when you need
  additional classes or html tags for different parts of the page.

* **dependencies**: a **list** of relative pathes to a folderes containing any dependencies your style guide has.
These folders will be copied over into the documentation output directory.
PUT THE CSS/JS THAT IS ACTUALLY BEING DOCUMENTED HERE

##### Example config file

    # The directory containing the source files to parse
    source: ../components

    # The directory that hologram will build to
    destination: ../docs

    # The assets needed to build/style the docs (includes header.html, footer.html, etc)
    documentation_assets: ../hologram_assets

    # A custom markdown renderer that extends `RedCarpet::Render::HTML class`
    custom_markdown: trulia_markdown_renderer.rb

    # Any other asset folders that need to be copied to the destination folder
    # This is where the CSS/JS you are actually documenting should go
    dependencies:
        - ../build



###Documenting your styles

Hologram will scan any css/scss/less files within your **source** directory.
It will look for comments that match the following:

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

The first section of the comment is a yaml block that defines certain
aspects of the this documentation block. The second part is simply
markdown as defined by Redcarpet.

####Document YAML section
The yaml in the doc block can have any key value pair you deem important
but it specifically looks for the following keys:

* **title**: The title to display in the documents
* **category**: This is the broad category for the component, all
  components in the same category will be written to the same page.
  (Usually named the same as the category but with spaces replaced with
  underscores and lower cased).
* **name**: This is used for grouping components, by assigning
  a name a component can be referenced in another component as a parent.
* **parent**: Optional. If this is set the current component will be
  displayed as a section within the parent's documentation.


###Documentation Assets

The documentation assets folder contains the html, css, js and images
you'll need for making your style guide look beautiful.

Hologram doesn't care too much about to what is in here as it is intended
to be custom for your style guide.

However, it does look for two files called header.html and footer.html.
These are html fragments that will be used when creating a new category page.
`header.html` will be copied to the beginning to the page and `footer.html`
will be copied to the bottom of the page. This gives you control of how you
will navigate your docs and lets you include any css, disclaimer text, and
whatever else you need on each page.

#####Styling Your Code Examples

Hologram uses [pygments.rb](https://github.com/tmm1/pygments.rb) gem to provide
syntax highlighting for code examples. One of the assets that you probably want
to include in your documentation assets folder is a css file that styles the
"pygmentized" code examples. We use `github.css` which can be found along with the
css we use to style code blocks [here](https://github.com/trulia/hologram-example/tree/gh-pages/hologram_assets/doc_assets/css).

## Supported Preprocessors/File Types

The following preprocessors/file types are supported by Hologram:
- Sass (.scss, .sass)
- Less (.less)
- Stylus (.styl)
- Vanilla CSS (.css)
- Javascript (.js)
- Markdown (.md, .markdown)

## Contributing

1. Fork it
2. Create your feature/bug fix branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## License
[Hologram is licensed under the MIT License](https://github.com/trulia/hologram/blob/master/LICENSE.txt)


