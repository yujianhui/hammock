module Hammock
  module RouteSetPatches
    MixInto = ActionController::Routing::RouteSet

    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      base.class_eval {
        attr_accessor :route_map
      }
    end

    module ClassMethods

    end

    module InstanceMethods

      private

      def initialize_hammock_route_map
        self.route_map = Hammock::RouteNode.new
      end

    end
  end
end
