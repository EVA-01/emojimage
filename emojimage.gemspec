# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'emojimage/version'

Gem::Specification.new do |spec|
  spec.name          = "emojimage"
  spec.version       = Emojimage::VERSION
  spec.authors       = ["James Anthony Bruno"]
  spec.email         = ["j.bruno.che@gmail.com"]

  spec.summary       = "Turn images into collages of emoji"
  spec.description   = "Turn images into collages of emoji"
  spec.homepage      = "https://github.com/EVA-01/emojimage"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_runtime_dependency "gemoji", "~> 2.1.0"
  spec.add_runtime_dependency "json", "~> 1.8.3"
  spec.add_runtime_dependency "oily_png", "~> 1.2.0"
  spec.add_runtime_dependency "thor", "~> 0.19.1"
end
