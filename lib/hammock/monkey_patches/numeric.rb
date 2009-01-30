module Hammock
  module NumericPatches
    MixInto = Numeric

    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods # TODO maybe include in the metaclass instead of extending the class?

      base.class_eval {
        alias kb kilobytes
        alias mb megabytes
        alias gb gigabytes
        alias tb terabytes
      }
    end

    module ClassMethods

    end

    module InstanceMethods

    end
  end
end
