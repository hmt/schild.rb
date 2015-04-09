# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'schild/version'

Gem::Specification.new do |spec|
  spec.name          = "schild"
  spec.version       = Schild::VERSION
  spec.authors       = ["HMT"]
  spec.email         = ["dev@hmt.im"]
  spec.summary       = %q{Schild-API}
  spec.description   = %q{schild bietet eine Ruby-Schnittstelle zu SchilD-NRW-Datenbanken.}
  spec.homepage      = "https://github.com/hmt/schild"
  spec.license       = "Creative Commons Namensnennung 4.0 International Lizenz."
  spec.required_ruby_version = ">= 2.0"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5"
  spec.add_development_dependency "minitest-rg", "~> 5"
  spec.add_development_dependency "mysql2", "~> 0"
  spec.add_development_dependency "envyable", "~> 0"

  spec.add_runtime_dependency "sequel", "~> 4"
end
