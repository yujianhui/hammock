module Hammock
  module PathFor
    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      base.class_eval {
        helper_method :method_for, :path_for, :nested_path_for, :verb_for
      }
    end

    module ClassMethods
    end

    module InstanceMethods
      private

      class RouteMap

        def self.for verb, record
          map[record.resource][verb]
        end

        private

        def self.map
          @@route_map ||= ActionController::Routing::Routes.routes.hash_by(:resource, :verb) {|routes|
            RouteGroup.new routes
          }
        end
        
        class RouteGroup
          def initialize routes
            @routes = routes
          end

          attr_reader :routes

          def for *records
            opts = records.extract_options!

            routes.detect {|route|
              route.nesting_matches?(*records) && route.format_matches?(opts[:format])
            }
          end

          def render *records
            self.for(records).render *records
          end

        end
      end

      # def route_group_for verb, record, opts = {}
      #   RouteMap.for(verb, record)
      # end

      def resource_map
        @hammock_resource_map
      end
      
      def route_for *args
        verb = args.shift if args.first.is_a?(Symbol)
        # verb = verb_for requested_verb, args.last
        
        resource_map.route_for verb, *args
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

      def path_for *args
        args.delete_if &:nil?
        opts = args.last.is_a?(Hash) ? args.pop.symbolize_keys! : {}

        [ :controller, :action, :id ].each {|key|
          raise ArgumentError, "path_for() infers :#{key} from the resources you provided, so you don't need to specify it manually." if opts.delete key
        }

        requested_verb = args.shift if args.first.is_a?(Symbol)
        verb = verb_for requested_verb, args.last
        resource = args.pop.resource if recordless_verb?(verb) || !args.last.is_a?(ActiveRecord::Base)

        path = []
        path << verb unless implied_verb?(verb)
        path.concat args.map(&:base_model)
        path << resource.base_model.send_if(plural_verb?(verb), :pluralize) unless resource.nil?
        path << 'path'

        args.push({(resource || args.last).base_model => opts[:params]}) unless opts[:params].blank?

        # log "sending #{path.compact.join('_')}(#{args.map(&:inspect).join(', ')})"
        send path.compact.join('_'), *args
      end

      def nested_path_for *resources
        resources.delete_if &:nil?
        requested_verb = resources.shift if resources.first.is_a?(Symbol)
        args = @current_nested_records.dup.concat(resources)

        args.unshift(requested_verb) unless requested_verb.nil?
        path_for *args
      end

      private

      def recordless_verb? verb
        [ :index, :create, :new ].include? verb.to_sym
      end

      def plural_verb? verb
        [ :index, :create ].include? verb.to_sym
      end

      def implied_verb? verb
        [ :index, :create, :show, :update, :destroy ].include? verb.to_sym
      end

    end
  end
end
