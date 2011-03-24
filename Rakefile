require 'rubygems'
require 'bundler/setup'
require 'rake/testtask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the rescue_each plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

task :test => :check_dependencies

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "rescue_each"
    gem.summary = "Rescue multiple exceptions when enumerating over Enumerable or ActiveRecord objects"
    gem.email = "jason@jasoncodes.com"
    gem.homepage = "http://github.com/jasoncodes/rescue_each"
    gem.authors = ["Jason Weathered"]
    gem.has_rdoc = false
    gem.add_dependency 'activesupport'
    gem.add_development_dependency 'activerecord'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

desc "Open an IRB session with this library loaded"
task :console do
  sh "irb -rrubygems -I lib -r rescue_each.rb"
end

begin
  require 'rcov/rcovtask'
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
rescue LoadError
  task :rcov do
    raise "You must install the 'rcov' gem"
  end
end
