require "./lib/xchan/version"
Gem::Specification.new do |gem|
  gem.name = "xchan.rb"
  gem.authors = ["0x1eef"]
  gem.email = ["0x1eef@protonmail.com"]
  gem.homepage = "https://github.com/0x1eef/xchan.rb"
  gem.version = XChan::VERSION
  gem.licenses = ["MIT"]
  gem.files = `git ls-files`.split($/)
  gem.require_paths = ["lib"]
  gem.description = <<-DESCRIPTION.each_line.map(&:strip).join(" ")
  xchan.rb is a small library that implements a channel through serialization
  and UNIXSocket.pair - an xchan.rb channel allows for easily sending Ruby
  objects between parent and child Ruby processes.
  DESCRIPTION
  gem.summary = gem.description
  gem.add_development_dependency "yard", "~> 0.9"
  gem.add_development_dependency "redcarpet", "~> 3.5"
  gem.add_development_dependency "rspec", "~> 3.10"
  gem.add_development_dependency "standardrb", "~> 1.1"
end
