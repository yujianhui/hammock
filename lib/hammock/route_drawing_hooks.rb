module Hammock
  module RouteDrawingHooks
    MixInto = ActionController::Routing::RouteSet

    def self.included base # :nodoc:
      base.send :include, Methods

      base.class_eval {
        alias_method_chain_once :draw, :hammock_route_map_init
      }
    end

    module Methods

      def draw_with_hammock_route_map_init &block
        ActionController::Routing::Routes.send :initialize_hammock_route_map
        draw_without_hammock_route_map_init &block
      end

    end
  end
end
