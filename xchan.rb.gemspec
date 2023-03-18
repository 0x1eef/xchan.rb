# frozen_string_literal: true

require "./lib/xchan/version"
Gem::Specification.new do |gem|
  gem.name = "xchan.rb"
  gem.authors = ["0x1eef"]
  gem.email = ["0x1eef@protonmail.com"]
  gem.homepage = "https://github.com/0x1eef/xchan.rb#readme"
  gem.version = Chan::VERSION
  gem.licenses = ["0BSD"]
  gem.files = `git ls-files`.split($/)
  gem.require_paths = ["lib"]
  gem.summary = "An easy to use InterProcess Communication (IPC) library."
  gem.description = gem.summary
  gem.add_runtime_dependency "lockf.rb", "~> 0.7"
  gem.add_development_dependency "test-unit", "~> 3.5.7"
  gem.add_development_dependency "yard", "~> 0.9"
  gem.add_development_dependency "redcarpet", "~> 3.5"
  gem.add_development_dependency "standard", "~> 1.13"
  gem.add_development_dependency "test-cmd.rb", "~> 0.2"
end
