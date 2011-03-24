require 'rubygems'
gem 'test-unit'
gem 'activesupport'
require 'test/unit'
require 'active_support/test_case'
require 'active_record'
require 'rescue_each'

def capture_stderr
  s = StringIO.new
  oldstderr = $stderr
  $stderr = s
  yield
  s.string
ensure
  $stderr = oldstderr
end

class Post < ActiveRecord::Base
  establish_connection :adapter => 'sqlite3', :database => ':memory:'
  connection.create_table :post do |t|
    t.string :name
  end
end
