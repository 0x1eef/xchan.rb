require './lib/xchan/version'
Gem::Specification.new do |gem|
  gem.name          = "xchan.rb"
  gem.authors       = ["Robert Gleeson"]
  gem.email         = ["1xab@protonmail.com"]
  gem.homepage      = "https://github.com/rg-3/xchan.rb"
  gem.version       = XChan::VERSION
  gem.licenses      = ["MIT"]
  gem.files         = `git ls-files`.split($/)
  gem.require_paths = ["lib"]
  gem.description   = <<-DESCRIPTION.each_line.map(&:strip).join(' ')
  xchan.rb is a small and easy to use library for sharing Ruby objects between Ruby
  processes who have a parent-child relationship.
  DESCRIPTION
  gem.summary = gem.description
end
