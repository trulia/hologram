# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hologram/version'

Gem::Specification.new do |spec|
  spec.name          = "hologram"
  spec.version       = Hologram::VERSION
  spec.authors       = ["JD Cantrell", "August Flanagan"]
  spec.email         = ["jcantrell@trulia.com"]
  spec.description   = %q{Build doc type things}
  spec.summary       = %q{Build document type things.}
  spec.homepage      = "http://trulia.github.io/hologram"
  spec.license       = "MIT"

  spec.add_dependency "redcarpet", ">= 2.2", "< 4.0"
  spec.add_dependency "rouge", ">= 1.5"
  spec.add_dependency "slim"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = ['hologram']
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 2.14"
end
