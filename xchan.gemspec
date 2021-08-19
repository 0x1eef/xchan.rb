require './lib/xchan/version'
Gem::Specification.new do |gem|
  gem.name          = "xchan.rb"
  gem.authors       = ["rg"]
  gem.email         = ["1aab@protonmail.com"]
  gem.homepage      = "https://github.com/0x1eef/xchan.rb"
  gem.version       = XChan::VERSION
  gem.licenses      = ["MIT"]
  gem.files         = `git ls-files`.split($/)
  gem.require_paths = ["lib"]
  gem.description   = <<-DESCRIPTION.each_line.map(&:strip).join(' ')
  xchan.rb is a small and easy to use library for sending and receiving 
  Ruby objects between Ruby processes who have a parent-child relationship.
  DESCRIPTION
  gem.summary = gem.description
end
