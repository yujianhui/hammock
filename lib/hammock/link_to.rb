module Hammock
  module LinkTo
    MixInto = ActionView::Base

    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods

      # Generate a restful link to verb the provided resources if the request would be allowed under the current scope.
      # If the scope would not allow the specified request, the link is ommitted entirely from the page.
      #
      # Use this method to render edit and delete links, and anything else that is only available to certain users or under certain conditions.
      def link_to_if_allowed verb, *resources
        opts = resources.last.is_a?(Hash) ? resources.pop.symbolize_keys! : {}
        record_or_resource = resources.last

        if :ok == can_verb_entity?(verb, record_or_resource)
          link_to opts.delete(:text) || verb.to_s.capitalize,
            path_for(verb, *resources),
            opts.merge(:method => (opts.delete(:method) || method_for(verb, record_or_resource)))
        end
      end

    end
  end
end
