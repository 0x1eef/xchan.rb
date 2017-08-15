Kernel.require './lib/zchannel/version'
Gem::Specification.new do |gem|
  gem.name          = "zchannel"
  gem.version       = ZChannel::VERSION
  gem.authors       = ["1xAB Software"]
  gem.email         = ["0xAB@protonmail.com"]
  gem.description   = %q{Provides an easy to use abstraction for sharing Ruby objects between Ruby processes.}
  gem.summary       = gem.description
  gem.homepage      = "https://gitlab.com/0xAB/zchannel"
  gem.licenses      = ["MIT"]
  gem.files         = `git ls-files`.split($/)
  gem.require_paths = ["lib"]
end
