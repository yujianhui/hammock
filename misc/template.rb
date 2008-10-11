module Hammock
  module Lol
    MixInto = Lol::Lul
    
    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods
    end
  end
end
