module Hammock
  module EnumerablePatches
    MixInto = Enumerable

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

    end
  end
end