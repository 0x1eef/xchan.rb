Kernel.require './lib/zchannel/version'
Gem::Specification.new do |gem|
  gem.name          = "zchannel.rb"
  gem.version       = ZChannel::VERSION
  gem.authors       = ["Robert Gleeson"]
  gem.email         = ["trebor8@protonmail.com"]
  gem.description   = %q{zchannel.rb provides an easy to use abstraction for sharing Ruby objects between Ruby processes who share a parent-child relationship.}
  gem.summary       = gem.description
  gem.homepage      = "https://github.com/r-obert/zchannel.rb"
  gem.licenses      = ["MIT"]
  gem.files         = `git ls-files`.split($/)
  gem.require_paths = ["lib"]
  gem.required_ruby_version = ">= 2.1"
  gem.add_development_dependency "rubygems-tasks"
  gem.add_development_dependency "rake"
end
