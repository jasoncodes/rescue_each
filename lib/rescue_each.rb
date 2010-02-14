module RescueEach
  class Error < StandardError
    
    attr_reader :errors
    
    def initialize(errors)
      @errors = errors
    end
    
    class Item < Struct.new :exception, :args
      
      def title
        "#{exception.message} (#{exception.class})"
      end
      def args_short
        args_str = args.map do |arg|
          lines = arg.inspect.lines.collect
          if lines.size == 1
            lines.first
          else
            lines.first + " [#{lines.size-1} more...]"
          end
        end
        "args: " + args_str.join(", ")
      end
      def args_full
        "args: #{args.inspect}"
      end
      def backtrace_s
        "\t#{exception.backtrace.join "\n\t"}"
      end
      
      def short_message
        "#{title} (#{args_short})"
      end
      
      def message
        "#{title}\n#{args_full}\n#{backtrace_s}"
      end
      
      def to_s
        "\n#{message}"
      end
      
    end
    
    def to_s
      msg = []
      errors.each_with_index do |error, idx|
        msg << "rescue_each catch ##{idx+1}: "
        msg << error.to_s
        msg << "\n"
      end
      msg << "rescue_each caught #{errors.size} errors"
      msg.join
    end
    
  end
end

module Enumerable
  
  def rescue_each(options = {})
    
    options.assert_valid_keys :stderr, :method
    options.reverse_merge! :method => :each
    
    errors = []
    send options[:method] do |*args|
      begin
        yield *args
      rescue Exception => e
        item = RescueEach::Error::Item.new e, args
        if options[:stderr] == :full
          $stderr.puts "rescue_each error: #{item}" if options[:stderr]
        elsif options[:stderr]
          $stderr.puts "rescue_each error: #{item.short_message}"
        end
        errors << item
      end
    end
    raise RescueEach::Error, errors unless errors.empty?
    self
  end
  
  def rescue_each_with_index(options = {}, &block)
    options = options.reverse_merge :method => :each_with_index
    rescue_each(options, &block)
  end
  
end
