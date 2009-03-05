module Hammock
  module RouteFor
    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      base.class_eval {
        helper_method :path_for, :nested_path_for, :route_for, :nested_route_for
      }
    end

    module ClassMethods
    end

    module InstanceMethods
      private

      def path_for *args
        route_for(*args).path
      end

      def nested_path_for *args
        nested_route_for(*args).path
      end

      def route_for *args
        opts = args.extract_options!
        verb = args.shift if args.first.is_a?(Symbol)

        ActionController::Routing::Routes.route_map.for verb_for(verb, args.last), args, opts
      end

      def verb_for requested_verb, record
        requested_verb = :show if requested_verb.blank?
        
        if (:show == requested_verb) && record.is_a?(Class)
          :index
        elsif :modify == requested_verb
          record.new_record? ? :new : :edit
        elsif :save == requested_verb
          record.new_record? ? :create : :update
        else
          requested_verb
        end
      end

      def nested_route_for *resources
        resources.delete_if &:nil?
        requested_verb = resources.shift if resources.first.is_a?(Symbol)
        args = current_nested_records.concat(resources)

        args.unshift(requested_verb) unless requested_verb.nil?
        route_for *args
      end

    end
  end
end
