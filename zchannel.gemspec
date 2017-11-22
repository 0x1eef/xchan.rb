Kernel.require './lib/zchannel/version'
Gem::Specification.new do |gem|
  gem.name          = "zchannel"
  gem.version       = ZChannel::VERSION
  gem.authors       = ["1xAB Software"]
  gem.email         = ["0x1eef@protonmail.com"]
  gem.description   = %q{Provides an easy to use abstraction for sharing Ruby objects between Ruby processes.}
  gem.summary       = %q{Provides an easy to use abstraction for sharing Ruby objects between Ruby processes who share a parent-child relationship. The implementation uses an unbound UNIXSocket, and a serializer of your choice, for sending Ruby objects between processes.}
  gem.homepage      = "https://gitlab.com/0xAB/zchannel"
  gem.licenses      = ["MIT"]
  gem.files         = `git ls-files`.split($/)
  gem.require_paths = ["lib"]
  gem.add_development_dependency "rubygems-tasks"
  gem.add_development_dependency "rake"
end
