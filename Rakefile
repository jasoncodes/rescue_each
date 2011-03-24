require 'rubygems'
require 'bundler/setup'
require 'rake/testtask'
require 'jeweler'
require 'rcov/rcovtask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the rescue_each plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

Jeweler::Tasks.new do |gem|
  gem.name = "rescue_each"
  gem.summary = "Rescue multiple exceptions when enumerating over Enumerable or ActiveRecord objects"
  gem.email = "jason@jasoncodes.com"
  gem.homepage = "http://github.com/jasoncodes/rescue_each"
  gem.authors = ["Jason Weathered"]
  gem.has_rdoc = false
end
Jeweler::GemcutterTasks.new

task :lib do
  $: << 'lib'
  require 'rescue_each'
end
task :console => :lib

Rcov::RcovTask.new do |t|
  t.libs << "test"
  t.rcov_opts = [
    "--exclude '^(?!lib)'"
  ]
  t.test_files = FileList[
    'test/**/*_test.rb'
  ]
  t.output_dir = 'coverage'
  t.verbose = true
end

task :rcov do
  system "open coverage/index.html"
end
