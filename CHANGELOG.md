#Changelog

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
