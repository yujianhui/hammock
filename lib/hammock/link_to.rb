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
      def hamlink_to *args
        opts = args.last.is_a?(Hash) ? args.pop.symbolize_keys! : {}
        verb = args.shift if args.first.is_a?(Symbol)
        record_or_resource = args.last
        method = (opts.delete(:method) || method_for(verb, record_or_resource))

        if :ok == can_verb_entity?(verb, record_or_resource)
          link_to verb_for(opts.delete(:text) || verb.to_s.capitalize, record_or_resource),
            path_for(verb, *args),
            opts.merge(:method => (method unless method == :get))
        end
      end

    end
  end
end
