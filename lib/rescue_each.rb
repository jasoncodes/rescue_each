require 'active_support'

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
  
  RESCUE_EACH_OPTIONS = [:stderr]
  
  def rescue_each(options = {})
    
    options.assert_valid_keys :method, :args, *RESCUE_EACH_OPTIONS
    options.reverse_merge! :method => :each
    options.reverse_merge! :args => []
    
    errors = []
    retval = send options[:method], *options[:args] do |*args|
      begin
        yield *args.dup
      rescue Exception => e
        
        item = RescueEach::Error::Item.new e, args
        if options[:stderr] == :full
          $stderr.puts "rescue_each error: #{item}" if options[:stderr]
        elsif options[:stderr]
          $stderr.puts "rescue_each error: #{item.short_message}"
        end
        
        if e.class.name == 'IRB::Abort'
          if errors.empty?
            raise
          else
            raise ::IRB::Abort, e.message + "\n" + RescueEach::Error.new(errors).to_s
          end
        end
        
        errors << item
        
      end
    end
    raise RescueEach::Error, errors unless errors.empty?
    return retval
  end
  
  def rescue_send(method, *args, &block)
    
    args = args.dup
    options = args.extract_options!
    rescue_options = options.reject { |k,v| !RESCUE_EACH_OPTIONS.include? k }
    options.except! *RESCUE_EACH_OPTIONS
    args << options unless options.empty?
    
    rescue_options[:method] = method
    rescue_options[:args] = args
    
    rescue_each rescue_options, &block
    
  end
  
  def rescue_map(*args, &block)
    rescue_send :map, *args, &block
  end
  
  def rescue_each_with_index(*args, &block)
    rescue_send :each_with_index, *args, &block
  end
  
  def rescue_find_each(*args, &block)
    rescue_send :find_each, *args, &block
  end
  
  def rescue_find_in_batches(*args, &block)
    rescue_send :find_in_batches, *args, &block
  end
  
end
