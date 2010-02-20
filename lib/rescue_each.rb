require 'active_support'

module RescueEach
  
  class Error < StandardError
    
    attr_reader :errors, :aborted
    
    def initialize(errors, aborted=false)
      @errors = errors
      @aborted = aborted
    end
    
    class Item < Struct.new :exception, :args
      
      def title
        "#{exception.message} (#{exception.class})"
      end
      def args_short
        args_str = args.map do |arg|
          str = arg.inspect
          max_length = 500
          if str.size > max_length
            str.slice(0, max_length) + " [#{str.size-max_length} more chars...]"
          else
            str
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
      msg << ", and then aborted." if aborted
      msg.join
    end
    
  end
  
  module CoreExt
    
    module Object
      
      RESCUE_EACH_OPTIONS = [:stderr, :error_limit]
      
      def rescue_each(options = {})
        
        options.assert_valid_keys :method, :args, *RESCUE_EACH_OPTIONS
        options.reverse_merge! :method => :each
        options.reverse_merge! :args => []
        
        errors = []
        retval = __send__ options[:method], *options[:args] do |*args|
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
            
            if options[:error_limit] && errors.size >= options[:error_limit]
              raise RescueEach::Error.new(errors, true)
            end
            
          end
        end
        raise RescueEach::Error, errors unless errors.empty?
        return retval
      end
      
      def rescue_send(method, *args, &block)
        
        args = args.dup
        options = args.extract_options!
        rescue_options = options.slice *RESCUE_EACH_OPTIONS
        options.except! *RESCUE_EACH_OPTIONS
        args << options unless options.empty?
        
        rescue_options[:method] = method
        rescue_options[:args] = args
        
        rescue_each rescue_options, &block
        
      end
      
    end
    
    module Enumerable
      def self.included(klass)
        klass.class_eval do
          
          def rescue_map(*args, &block)
            rescue_send :map, *args, &block
          end
          
          def rescue_each_with_index(*args, &block)
            rescue_send :each_with_index, *args, &block
          end
        
        end
      end
    end
    
  end
  
  module ActiveRecord
    def self.included(klass)
      klass.class_eval do
        
        def self.rescue_find_each(*args, &block)
          rescue_send :find_each, *args, &block
        end
        
        def self.rescue_find_in_batches(*args, &block)
          rescue_send :find_in_batches, *args, &block
        end
        
      end
    end
  end
  
end

Object.send(:include, RescueEach::CoreExt::Object)
Enumerable.send(:include, RescueEach::CoreExt::Enumerable)
ActiveRecord::Base.send(:include, RescueEach::ActiveRecord) if defined? ActiveRecord
