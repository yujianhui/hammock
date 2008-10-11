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

      # TODO Remove for Ruby 1.9
      def tap
        yield self
        self
      end

      def symbolize
        self.to_s.underscore.to_sym
      end

      def send_if condition, method_name, *args
        condition ? self.send(method_name, *args) : self
      end

    end
  end
end
