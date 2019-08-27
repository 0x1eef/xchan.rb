require './lib/xchannel/version'
Gem::Specification.new do |gem|
  gem.name          = "xchannel.rb"
  gem.authors       = ["0x1eef"]
  gem.email         = ["0x1eef@protonmail.com"]
  gem.homepage      = "https://github.com/0x1eef/xchannel.rb"
  gem.version       = XChannel::VERSION
  gem.licenses      = ["MIT"]
  gem.files         = `git ls-files`.split($/)
  gem.require_paths = ["lib"]
  gem.description   = <<-DESCRIPTION.each_line.map(&:strip).join(' ')
  xchannel.rb is a small and easy to use library for sharing Ruby objects between Ruby
  processes who have a parent-child relationship.
  DESCRIPTION
  gem.summary = gem.description
end
