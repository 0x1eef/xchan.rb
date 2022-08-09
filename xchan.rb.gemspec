# frozen_string_literal: true

require "./lib/xchan/version"
Gem::Specification.new do |gem|
  gem.name = "xchan.rb"
  gem.authors = ["0x1eef"]
  gem.email = ["0x1eef@protonmail.com"]
  gem.homepage = "https://github.com/0x1eef/xchan.rb"
  gem.version = Chan::VERSION
  gem.licenses = ["MIT"]
  gem.files = `git ls-files`.split($/)
  gem.require_paths = ["lib"]
  gem.summary = "A library for sending Ruby objects between Ruby processes."
  gem.description = <<-DESCRIPTION.each_line.map(&:strip).join(" ")
  xchan.rb is a library for sending Ruby objects between Ruby processes who have
  a parent <=> child relationship.
  DESCRIPTION
  gem.add_runtime_dependency "lockf.rb", "~> 0.3.1"
  gem.add_development_dependency "yard", "~> 0.9"
  gem.add_development_dependency "redcarpet", "~> 3.5"
  gem.add_development_dependency "rspec", "~> 3.10"
  gem.add_development_dependency "standard", "~> 1.13"
  gem.add_development_dependency "rubocop-rspec", "~> 2.11"
end
