#Changelog

##1.4.0 - 2015-03-29

New Features:

Joe Bartlett
* Allow markdown files to contain hologram yaml

Anthony Chen
* Add config option for allowing additional file extensions to be
  processed

JD Cantrell
* Add config option to ignore specific paths and files.

Bug fixes:

Noppanit Charassinvichai and Ryan Mathews
* Correctly copy assets

JD Cantrell
* Use correct title for index category pages
* Make scss regex behave like sass regex
* Template variables for erb files no longer vary based on when the erb
  is processed.


##1.3.0 - 2015-01-15

Spencer Hurst, Beatrice Peng, and Geoff Pleiss
* Overhaul the code examples code to allow easier customization

Nicole Sullivan and Geoff Pleiss
* Add class styleguide to generated markdown documentation
* Add nav_level config and section navigation
* Tabular code examples (ie html_example_table, haml_example_table, etc)

Paul Meskers and Nicole Sullivan
* Add code example support for JSX

Geoff Pleiss
* Add config to exit on warnings
* Add internal reference links for linking to other sections within
  hologram's generated documentation

Jonathan Dexter
* Fix document comment block regex to work with CR

Beatrice Peng
* Warn when multiple components have the same name

Chris Holmes
* Documentation updates

Antoine - a5e
* Escape title in documentation block

JD Cantrell
* Try .sass style comments when a .scss file has no doc blocks
* Remove all backtick commands with FileUtils call (better support on
  non-linux/osx machines)
* Add code example support for slim


##1.2.0 - 2014-07-22

JD Cantrell
* Replace pygments with rouge
* Add in initial plugin support

Todd Sedano
* Update specs to use `be_truthy` and `be_falsy` (fixes deprecation
  warnings)

Carsten Zimmermann
* Update redcarpet dependency to use newer versions of redcarpet

Geoffrey Giesemann, Vanessa de Sant Anna, Nicole Sullivan
* Add support for multiple source directories in the hologram config

rishabhsrao
* Remove the --root command line flag

Marek
* Add missing div tag in `_header.html`

Todd Sedano, bigethan, August Flanagan, JD Cantrell
* Many useful readme updates

##1.1.0 - 2014-05-13

Rajan Agaskar, Dominick Reinhold, and Nicole Sullivan
* Support multiple categories
* Create assets when output directory does not exist

jho406
* Major Clean up and refactors
* Code climate badge
* Readme updates
* Spec updates


JD Cantrell
* Use UTF-8 as default encoding
* Do not error when a directory name matches a supported file type
* Sort documentation blocks case insensitively
* Support .erb files
* Pass in config and full pages object to .erb templates
* If title does not exist default it to title with underscores
* Display an error when a documentation block does not have a category
* Warn when the parent block is specified but could not be found
* Add -c flag for specifying config (you may still specify the config as
  the first parameter to hologram)

August Flanagan
* Remove rspec as a runtime dependency

James Myers & Madhura Bhave
* A rendering scope can now be defined when using haml_examples

Mike Wilkes
* Documentation clean ups
* Fix a typo in the config template
