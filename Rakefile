require 'bundler/gem_tasks'
require 'rake/testtask'
require "rubygems/tasks"
Gem::Tasks.new
task :test do
  sh "ruby test/zchannel_test.rb"
end
task default: :test
