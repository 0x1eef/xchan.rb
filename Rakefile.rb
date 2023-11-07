require "rake/testtask"
require "bundler/setup"

Rake::TestTask.new do |t|
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
  t.warning = false
end
task default: :test
