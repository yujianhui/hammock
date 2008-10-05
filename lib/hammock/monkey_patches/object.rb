module Hammock
  module ObjectPatches
    MixInto = Object
    
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods

      def symbolize
        self.to_s.underscore.to_sym
      end

    end
  end
end
