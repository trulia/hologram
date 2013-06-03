# Hologram

Hologram is a Ruby gem that parses comments in your CSS and turns them into a beautiful style guide.

## Installation

Add this line to your application's Gemfile:

    gem 'hologram'

And then execute:

    $ bundle
    
If you don't use bundler you can run `gem install hologram`.

## Usage

There are two things you need to do to start using hologram
1. Setup a YAML config file

2. Document a some code
 
### Creating a config file

Hologram needs a few configuration settings before it can begin to build
your documentation for you. Once this is set up you can execute hologram by 
simply running:

    hologram path/to/your/config.yml
    or (using bundler)
    bundle exec hologram path/to/your/config.yml

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
  components in the same category will be displayed on a single page in
  Hologram's output (e.g. anything with the category "Base CSS" will end 
up on a page called base_css.html).
* **name**: This is used for organizing components, by assigning
  a name a component can be referenced in another component as a **parent**.
* **parent**: Optional. If this is set the current component will be
  displayed as a section within the parent's documentation.


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
