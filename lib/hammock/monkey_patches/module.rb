module Hammock
  module ModulePatches
    MixInto = Module
    LoadFirst = true

    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods

      def alias_method_chain_once target, feature
        aliased_target, punctuation = target.to_s.sub(/([?!=])$/, ''), $1
        without_method = "#{aliased_target}_without_#{feature}#{punctuation}"

        unless [public_instance_methods, protected_instance_methods, private_instance_methods].flatten.include? without_method
          alias_method_chain target, feature
        end
      end

    end
  end
end
