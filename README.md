# Hologram
[![Build Status](https://travis-ci.org/trulia/hologram.png)](https://travis-ci.org/trulia/hologram)
[![Code Climate](https://codeclimate.com/github/trulia/hologram.png)](https://codeclimate.com/github/trulia/hologram)

Hologram is a Ruby gem that parses comments in your CSS and helps you
turn them into a beautiful style guide.

There are two steps to building a great style guide:

1. Documenting your css and javascript, and generating html examples.
2. Styling the output of step 1.

The hologram gem itself is only concerned with step 1. This means you
are free to make your style guide look however you would like. If you
don't feel like going through this process yourself, you can take a look
at the
[templates](https://github.com/trulia/hologram-example/tree/master/templates)
in our [example repository](https://github.com/trulia/hologram-example),
and use the assets defined there instead.


## Installation

Add this line to your application's Gemfile:

    gem 'hologram'

And then execute:

    $ bundle

If you don't use bundler you can run `gem install hologram`.


## Quick Start

``` hologram init ```

This will create a `hologram_config.yml` file  (more on this below), and
also create a starter `_header.html` and `_footer.html` file for you.
You can then tweak the config values and start documenting your css.

Add some documentation to one of your stylesheets:

    /*doc
    ---
    title: Alert
    name: alert
    category: basics
    ---
    ```html_example
        <div class='alert'>Hello</div>
    ```
    */

Building the documentation is simply:

``` hologram ```


###Command line flags

Hologram has a couple of command line flags:

* `-c` or `--config` - specify the config file, by default hologram
  looks for `hologram_config.yml`

## Details

There are two things you need to do to start using hologram:

1. Create a YAML config file for your project.

2. Go document some code!


### Creating a YAML config file

Hologram needs a few configuration settings before it can begin to build
your documentation for you. Once this is set up, you can execute hologram
by simply running:

`hologram path/to/your/config.yml` or (using bundler) `bundle exec
hologram path/to/your/config.yml`

Your config file needs to contain the following key/value pairs

* **source**: relative path(s) to your source files. Accepts either a
  single value or an array

* **destination**: relative path where you want the documentation to be
  built

* **documentation_assets**: The path that contains supporting assets for
  the documentation page. This typically includes html fragments
  (header/footer, etc), style guide specific CSS, javascript and any
  images. Hologram specifically looks for two files: `_header.html` and
  `_footer.html`. These are used to start and end every html page
  hologram generates.

  Hologram treats `_header.html` and `_footer.html` as ERB files for
  each page that is generated. You can access the `title`, `file_name`,
  `blocks`, and `categories`.

  `blocks` is a list of each documentation block on the page. Each item
  in the list has a `title`, `name`, `category`, and optionally a
  `parent`. This is useful for, say, building a menu that lists each
  component.

  `categories` is a list of all the categories found in the
  documentation

  **Nota Bene:** Filenames that begin with underscores will not be
  copied into the destination folder.

* **custom_markdown**: (optional) this is the filename of a class that
  extends RedCarpet::Render::HTML class. Use this for when you need
  additional classes or html tags for different parts of the page.  See
  `example_markdown_renderer.rb.example` for an example of what your
  class can look like.

* **index**: (optional) this is a category (see **Documenting your
  styles** section below) that will be used as the index.html.

* **dependencies**: a **list** of relative paths to folders containing
  any dependencies your style guide has. These folders will be copied
  over into the documentation output directory. ENSURE THE CSS/JS THAT IS
  ACTUALLY BEING DOCUMENTED IS LISTED HERE. You will also need to ensure
   that they are included on your pages. A simple way to do this is to add
   `<link>` and `<script src=>` tags to the `_header.html` file.


##### Example config file

    # Hologram will run from same directory where this config file resides
    # All paths should be relative to there

    # The directory containing the source files to parse recursively
    source: ./sass

    # You may alternately specify multiple directories.
    # source:
    #  - ./sass
    #  - ./library-sass

    # The directory that hologram will build to
    destination: ./docs

    # The assets needed to build the docs (includes header.html,
    # footer.html, etc)
    # You may put doc related assets here too: images, css, etc.
    documentation_assets: ./doc_assets

    # Any other asset folders that need to be copied to the destination
    # folder. Typically this will include the css that you are trying to
    # document. May also include additional folders as needed.
    dependencies:
      - ./build

    # Mark which category should be the index page
    # Alternatively, you may have an index.md in the documentation assets
    # folder instead of specifying this config.
    index: basics

### Documenting your styles and components

Hologram will scan for stylesheets (.css, .scss, .sass, .less, or .styl)
and javascript source files (.js) within the **source** directory defined
in your configuration.  It will look for comments that match the following:

    /*doc
    ---
    title: Buttons
    name: button
    category: Base CSS
    ---

    Button styles can be applied to any element. Typically you'll want
    to use either a `<button>` or an `<a>` element:

    ```html_example <button class="btn btnDefault">Click</button> <a
    class="btn btnDefault" href="trulia.com">Trulia!</a> ```

    If your button is actually a link to another page, please use the
    `<a>` element, while if your button performs an action, such as
    submitting a form or triggering some javascript event, then use a
    `<button>` element.

    */

**NB:** Sass users who are using the `.sass` flavor of Sass should use `//doc` style comments with indents to create their comment blocks.

The first section of the comment is a YAML block that defines certain
aspects of this documentation block (more on that in the next
section). The second part is simply markdown as defined by Redcarpet.

Notice the use of `html_example`. This tells the markdown renderer that
it should treat the example as...well...html. If your project uses
[haml](http://haml.info/) you can also use `haml_example`. In that case
the output will be html for the example and the code block will show the
haml used to generate the html.

For components that require [javascript](https://www.destroyallsoftware.com/talks/wat)
you can use `js_example`. In addition to outputting the javascript in a
`<code>` block it will also wrap it in a `<script>` tag for execution.

Additionally, html elements that are generated via markdown will have a
class `styleguide` appended to them. You can use this to apply css to
the styleguide itself.

#### Document YAML section

The YAML in the documentation block can have any
key/value pairs you deem important, but it specifically looks for the
following keys:

* **title**: The title to display in the documents
* **category/categories**: This is the broad categories for the component, all
  components in the same category will be written to the same page. It can be set to either a string or a YAML array. If you use an array, the component will be written to both pages.
  Note: There is no need to set a category if this component has a **parent**.
* **name**: This is used for grouping components, by assigning a name, a
  component can be referenced in another component as a parent. Note that items in
  the same category are sorted alphabetically by name.
* **parent**: (Optional.) This should be the **name** of another
  component. If this is set, the current component will be displayed as
  a section within the **parent**'s documentation, but only if it specifies
  the same **category**, or allows the **category** to be inherited from its **parent**.

For example, you might have a component with the **name** *buttons* and
another component named *buttonSkins*. You could set the **parent** for
the *buttonSkins* component to be *buttons*. It would then nest the
*buttonSkins* documentation inside the *buttons* documentation.

Each level of nesting (components are infinitely nestable) will have a
heading tag that represents its depth. In the above example *buttons*
would have an `<h1>` and *buttonSkins* would have an `<h2>`.

You can see [this exact example in our demo
repo](https://github.com/trulia/hologram-example/tree/master/components/button),
and the output of this nesting [in our demo
style guide](http://trulia.github.io/hologram-example/base_css.html#Buttons).


### Documentation Assets

The documentation assets folder contains the html, css, js and images
you'll need for making your style guide look beautiful.

Hologram doesn't care too much about what is in here as it is
intended to be custom for your style guide.


##### Styling Your Code Examples

Hologram uses [pygments.rb](https://github.com/tmm1/pygments.rb) gem to
provide syntax highlighting for code examples. One of the assets that
you probably want to include in your documentation assets folder is a
css file that styles the "pygmentized" code examples. We use
`github.css` which can be found along with the css we use to style code
blocks
[here](https://github.com/trulia/hologram-example/tree/gh-pages/hologram_assets/doc_assets/css).


## Supported Preprocessors/File Types

The following preprocessors/file types are supported by Hologram:
- Sass (.scss, .sass)
- Less (.less)
- Stylus (.styl)
- Vanilla CSS (.css)
- Javascript (.js)
- Markdown (.md, .markdown)


## Extensions and Plugins

- [Guard Hologram](https://github.com/kmayer/guard-hologram) is a sweet
  little gem that uses guard to monitor changes to your hologram project
  and rebuilds your style guide on the fly as you make changes.
- [Grunt Hologram](https://github.com/jchild3rs/grunt-hologram/) is a sweet
  little grunt task that will generate your hologram style guide.
- [Classname Clicker](https://github.com/bigethan/hologram-addons/) is a handy
  UI addition that gives the ability to see rules that apply to a classname by
  clicking on them within hologram.
- [Cortana](https://github.com/Yago/Cortana) is a theme for hologram. It also
  includes a handy search feature.

## Contributing

1. Fork it
2. Create your feature/bug fix branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## Authors

Hologram is written and maintained by [August
Flanagan](http://github.com/aflanagan) and [JD
Cantrell](http://github.com/jdcantrell).


## Contributors

These fine people have also contributed to making hologram a better gem:

* [Rajan Agaskar](https://github.com/ragaskar)
* Louis Bennett
* [jho406](https://github.com/jho406)
* johny (wrote our initial tests!)
* [Elana Koren](https://github.com/elanakoren)
* [Ken Mayer](https://github.com/kmayer)
* [Roberto Ostinelli](https://github.com/ostinelli)
* [Dominick Reinhold](https://github.com/d-reinhold)
* [Nicole Sullivan](https://github.com/stubbornella)
* [Mike Wilkes](https://github.com/mikezx6r)
* [Vanessa Sant'Anna](https://github.com/vsanta)
* [Geoffrey Giesemann](https://github.com/geoffwa)


## License

[Hologram is licensed under the MIT License](https://github.com/trulia/hologram/blob/master/LICENSE.txt)
