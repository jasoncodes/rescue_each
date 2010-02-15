require 'rubygems'
gem 'test-unit'
require 'test/unit'
require 'active_support'
require 'active_support/test_case'
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
