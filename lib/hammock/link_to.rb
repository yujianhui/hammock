module Hammock
  module LinkTo
    MixInto = ActionView::Base

    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods

      def link_to_if_allowed verb, *resources
        opts = resources.last.is_a?(Hash) ? resources.pop.symbolize_keys! : {}
        record_or_resource = resources.last

        if :ok == can_verb_entity?(verb, record_or_resource)
          link_to opts.delete(:text) || verb.to_s.capitalize,
            path_for(verb, resources),
            opts.merge(:method => (opts.delete(:method) || method_for(verb, record_or_resource)))
        end
      end

    end
  end
end
