Kernel.require './lib/xchannel/version'
Gem::Specification.new do |gem|
  gem.name          = "xchannel.rb"
  gem.version       = XChannel::VERSION
  gem.authors       = ["0x1eef"]
  gem.email         = ["0x1eef@protonmail.com"]
  gem.description   = %q{xchannel.rb provides an easy to use abstraction for sharing Ruby objects between Ruby processes who share a parent-child relationship.}
  gem.summary       = gem.description
  gem.homepage      = "https://github.com/0x1eef/xchannel.rb"
  gem.licenses      = ["MIT"]
  gem.files         = `git ls-files`.split($/)
  gem.require_paths = ["lib"]
  gem.required_ruby_version = ">= 2.1"
  gem.add_development_dependency "rubygems-tasks"
  gem.add_development_dependency "rake"
end
