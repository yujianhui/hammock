module Hammock
  module ResourceMappingHooks
    MixInto = ActionController::Resources

    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      base.class_eval {
        # unless defined?(:map_resource_without_hammock_hook)
        alias_method_chain :map_resource, :hammock_hook
        alias_method_chain :map_singleton_resource, :hammock_hook
      }
    end

    module ClassMethods

    end

    module InstanceMethods

      private

      def map_resource_with_hammock_hook entity, options = {}, &block
        ActionController::Routing::Routes.route_map.add entity, options
        map_resource_without_hammock_hook entity, options, &block
      end

      def map_singleton_resource_with_hammock_hook entity, options = {}, &block
        ActionController::Routing::Routes.route_map.add_singleton entity, options
        map_singleton_resource_without_hammock_hook entity, options.dup, &block
      end

    end
  end
end
