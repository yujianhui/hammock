module Hammock
  module ObjectPatches
    MixInto = Object

    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      base.class_eval {
        alias is_an? is_a?
      }
    end

    module ClassMethods
    end

    module InstanceMethods

      # Return +self+ after yielding to the given block.
      #
      # Useful for inline logging and diagnostics. Consider the following:
      #     @items.map {|i| process(i) }.join(", ")
      # With +tap+, adding intermediate logging is simple:
      #     @items.map {|i| process(i) }.tap {|obj| log obj.inspect }.join(", ")
      #--
      # TODO Remove for Ruby 1.9
      def tap
        yield self
        self
      end
      
      # The reverse of <tt>Enumerable#include?</tt> - returns +true+ if +self+ is
      # equal to one of the elements of +args+.
      def in? *args
        args.include? self
      end

      # A symbolized, underscored (i.e. reverse-camelized) representation of +self+.
      #
      # Examples:
      #
      #     Hash.symbolize                     #=> :hash
      #     ActiveRecord::Base.symbolize       #=> :"active_record/base"
      #     "GetThisCamelOffMyCase".symbolize  #=> :get_this_camel_off_my_case
      def symbolize
        self.to_s.underscore.to_sym
      end

      # If +condition+ evaluates to true, return the result of sending +method_name+ to +self+; <tt>*args</tt> to +self+, otherwise, return +self+ as-is.
      def send_if condition, method_name, *args
        condition ? send(method_name, *args) : self
      end

      # If +condition+ evaluates to true, return the result of sending +method_name+ to +self+; <tt>*args</tt> to +self+, otherwise, return +self+ as-is.
      def send_if_respond_to method_name, *args
        send_if respond_to?(method_name), method_name, *args
      end

    end
  end
end
