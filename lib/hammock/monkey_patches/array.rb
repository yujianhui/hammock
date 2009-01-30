module Hammock
  module ArrayPatches
    MixInto = Array

    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods

      # Returns true iff +other+ appears exactly at the start of +self+.
      def starts_with? *other
        self[0, other.length] == other
      end

      # Returns true iff +other+ appears exactly at the end of +self+.
      def ends_with? *other
        self[-other.length, other.length] == other
      end

      def squash
        self.dup.squash!
      end
      def squash!
        self.delete_if &:blank?
      end

      def discard *args
        self.dup.discard! *args
      end
      def discard! *args
        args.each {|arg| self.delete arg }
        self
      end

      def as_index_for &value_function
        inject({}) do |accum, elem|
          accum[elem] = value_function.call(elem)
          accum
        end
      end

      def remove_framework_backtrace
        reverse.drop_while {|step|
          !step.starts_with?(RAILS_ROOT)
        }.reverse
      end

      def hash_by *methods, &block
        hsh = Hash.new {|h,k| h[k] = [] }
        this_method = methods.shift

        # First, hash this array into +hsh+.
        self.each {|i| hsh[i.send(this_method)] << i }

        if methods.empty?
          # If there are no methods remaining, yield this group to the block if required.
          hsh.each_pair {|k,v| hsh[k] = yield(hsh[k]) } if block_given?
        else
          # Recursively hash remaining methods.
          hsh.each_pair {|k,v| hsh[k] = v.hash_by(*methods, &block) }
        end

        hsh
      end

    end
  end
end
