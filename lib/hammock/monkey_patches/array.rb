module Hammock
  module ArrayPatches
    MixInto = Array
    
    def self.included base
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

    end
  end
end
