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
      def link_to_if_allowed verb, record_or_resource, opts = {}
        allowed = if record_or_resource.is_a?(ActiveRecord::Base)
          can_verb_record? verb, record_or_resource
        else
          can_verb_resource? verb, record_or_resource
        end

        if :ok == allowed
          link_to opts.delete(:text) || verb.to_s.capitalize,
            path_for(verb, record_or_resource, opts),
            :method => method_for(verb, record_or_resource)
        end
      end
    end
  end
end
