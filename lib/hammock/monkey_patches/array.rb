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

    end
  end
end
