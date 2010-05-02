require 'test_helper'

class RescueEachTest < ActiveSupport::TestCase
  
  test "return value" do
    enum = (1..5)
    assert_equal enum, enum.each(&:nil?)
  end
  
  test "calls block" do
    output = []
    (1..5).rescue_each do |x|
      output << x
    end
    assert_equal (1..5).collect, output
  end
  
  test "continues after an error" do
    error_object = nil
    output = []
    begin
      (1..5).rescue_each do |x|
        output << x
        raise 'test' if x == 3
      end
    rescue RescueEach::Error => e
      error_object = e
    end
    assert_equal (1..5).collect, output
    assert_false error_object.aborted
    assert_no_match /and then aborted/, error_object.to_s.lines.collect.last
  end
  
  test "stops after error limit" do
    error_object = nil
    output = []
    begin
      (1..10).rescue_each :error_limit => 3 do |x|
        output << x
        raise 'test' if x%2 == 0
      end
    rescue RescueEach::Error => e
      error_object = e
    end
    assert_equal (1..6).collect, output
    assert_true error_object.aborted
    assert_match /and then aborted/, error_object.to_s.lines.collect.last
  end
  
  test "empty array doesn't call block" do
    [].rescue_each do
      raise 'test'
    end
  end
  
  test "empty block doesn't raise" do
    [42].rescue_each do
    end
  end
  
  test "no param block can raise" do
    assert_raise RescueEach::Error do
      [42].rescue_each do
        raise 'test'
      end
    end
  end
  
  test "rescue_each_with_index args pass through correctly with 2 params" do
    output = []
    [:foo, :bar].rescue_each_with_index do |obj,i|
      output << [obj,i]
    end
    expected = [[:foo, 0], [:bar, 1]]
    assert_equal expected, output
  end
  
  test "rescue_each_with_index args pass through correctly args param" do
    output = []
    [:foo, :bar].rescue_each_with_index do |*args|
      output << args
    end
    expected = [[:foo, 0], [:bar, 1]]
    assert_equal expected, output
  end
  
  test "Hash#rescue_each args for single block param" do
    input = {:foo => 42, :bar => 12}
    output = []
    input.rescue_each do |args|
      output << args
    end
    assert_equal input.to_a, output
  end
  
  test "Hash#rescue_each args for key/value block params" do
    input = {:foo => 42, :bar => 12}
    output = []
    input.rescue_each do |k, v|
      output << [k,v]
    end
    assert_equal input.to_a, output
  end
  
  test "error object contains args that triggered error" do
    error_object = nil
    begin
      (1..10).rescue_each do |i|
        raise 'foo' if (i%2) == 0
      end
    rescue RescueEach::Error => e
      error_object = e
    end
    assert_equal [[2],[4],[6],[8],[10]], error_object.errors.map(&:args)
  end
  
  test "error object contains args for Symbol#to_proc sugar" do
    error_object = nil
    begin
      [42].rescue_each &:foo
    rescue RescueEach::Error => e
      error_object = e
    end
    assert_equal [[42]], error_object.errors.map(&:args)
  end
  
  def foo_abc
    bar_def
  end
  
  def bar_def
    raise 'baz'
  end
  
  test "captured error message and backtrace" do
    
    error_object = nil
    begin
      [42].rescue_each do |i|
        foo_abc
      end
    rescue RescueEach::Error => e
      error_object = e
    end
    
    assert_equal 1, error_object.errors.size
    the_exception = error_object.errors.first.exception
    
    assert_kind_of RuntimeError, the_exception
    assert_equal 'baz', the_exception.message
    
    assert_true the_exception.backtrace.size > 2
    assert_match /:in `bar_def'\Z/, the_exception.backtrace[0]
    assert_match /:in `foo_abc'\Z/, the_exception.backtrace[1]
    
  end
  
  test "Ctrl-C in IRB should break out of the loop" do
    
    module ::IRB
      class Abort < Exception; end
    end
    
    error_object = nil
    output = []
    begin
      (1..5).rescue_each do |i|
        raise 'foo bar' if i == 2
        output << i
        raise ::IRB::Abort, 'abort then interrupt!!' if i == 4
      end
    rescue ::IRB::Abort => e
      error_object = e
    end
    
    assert_equal [1,3,4], output
    assert_kind_of ::IRB::Abort, error_object
    assert_match /abort then interrupt/, error_object.message
    assert_match /foo bar/, error_object.message
    
  end
  
  test "Ctrl-C from outside IRB should break out of the loop" do
    
    error_object = nil
    output = []
    begin
      (1..5).rescue_each do |i|
        raise 'foo bar' if i == 2
        output << i
        raise ::Interrupt if i == 4
      end
    rescue ::Interrupt => e
      error_object = e
    end
    
    assert_equal [1,3,4], output
    assert_kind_of ::Interrupt, error_object
    assert_match /foo bar/, error_object.message
    
  end
  
  test "no stderr option doesn't output to stderr" do
    err = capture_stderr do
      assert_raise RescueEach::Error do
        [42].rescue_each do
          raise 'foo bar'
        end
      end
    end
    assert_equal '', err
  end
  
  test "stderr option outputs to stderr" do
    err = capture_stderr do
      assert_raise RescueEach::Error do
        [42].rescue_each :stderr => true do
          raise 'foo bar'
        end
      end
    end
    assert_match /foo bar/, err
  end
  
  test "stderr output truncates long args" do
    
    err = capture_stderr do
      assert_raise RescueEach::Error do
        ['foo bar '*1000].rescue_each(:stderr => true) { raise 'foo' }
      end
    end
    
    assert_operator err.size, :>=, 100
    assert_operator err.size, :<=, 1000
    
  end
  
  test "rescue_send passes through args" do
    assert_true (1..5).rescue_send :include?, 3
    assert_false (1..5).rescue_send :include?, 6
  end
  
  test "rescue_send handles rescue_each options" do
    err = capture_stderr do
      assert_raise RescueEach::Error do
        [42].rescue_send :each, :stderr => true do
          raise 'lorem ipsum'
        end
      end
    end
    assert_match /lorem ipsum/, err
  end
  
  test "rescue_map returns output of proxied method" do
    output = (1..5).rescue_map { |x| x*x }
    assert_equal [1,4,9,16,25], output
  end
  
  test "rescue_send calls correct method and returns result" do
    odds = (1..5).rescue_send(:reject) { |i| i%2 == 0 }
    assert_false odds.empty?
    assert_true odds.all? &:odd?
  end
  
  test "rescued find methods exist on active record objects" do
    [:find_each, :find_in_batches].each do |method_base|
      ["#{method_base}", "rescue_#{method_base}"].each do |method|
        [ActiveRecord::Base, ActiveRecord::Base.scoped(:limit => 42)].each do |object|
          assert_true object.respond_to? method
        end
      end
    end
  end
  
end
