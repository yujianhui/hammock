module Hammock
  module HamlinkTo
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
        opts = args.extract_options!
        verb = args.first if args.first.is_a?(Symbol)
        entity = args.last

        if :ok == can_verb_entity?(verb, entity)
          route = route_for *args.push(opts.dragnet(:nest, :format))

          link_to(opts.delete(:text) || opts.delete(:text_or_else) || route.verb,
            route.path(opts.delete(:params)),
            opts.merge(:method => (route.http_method unless route.get?))
          )
        else
          opts[:else] || opts[:text_or_else]
        end
      end

    end
  end
end
