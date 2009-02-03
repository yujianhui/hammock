module Hammock
  module RouteSetPatches
    MixInto = ActionController::Routing::RouteSet

    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      base.class_eval {
        attr_accessor :route_map
      }

      ActionController::Routing::Routes.send :initialize_hammock_route_map
    end

    module ClassMethods

    end

    module InstanceMethods

      private

      def initialize_hammock_route_map
        self.route_map = HammockResource.new
      end

      class HammockResource < ActionController::Resources::Resource
        class HammockRoutePiece
          attr_reader :resource, :routeable_as, :verb, :entity, :parent

          def initialize resource
            @resource = resource
          end

          def for verb, entity
            routeable_as = resource.routeable_as(verb, entity)

            if !routeable_as
              raise "The verb '#{verb}' can't be applied to " + (entity.record? ? "#{entity.resource} records" : "the #{entity.resource} resource") + "."
            elsif (:record == routeable_as) && entity.new_record?
              raise "The verb '#{verb}' requires a #{entity.resource} with an ID (i.e. not a new record)."
            else
              @verb, @entity, @routeable_as = verb, entity, routeable_as
            end

            self
          end

          def within parent
            @parent = parent
            self
          end
          
          def setup?
            !@entity.nil?
          end
          
          def path
            raise_unless_setup_while_trying_to 'render a path'

            buf = entity.resource_name
            buf << '/' + entity.to_param if entity.record?
            buf << '/' + verb.to_s unless verb.nil? or implied_verb?(verb)
            buf

            if parent.nil?
              buf
            else
              parent.path + '/' + buf
            end
          end
          
          def http_method
            raise_unless_setup_while_trying_to 'extract the HTTP method'
            resource.send("#{routeable_as}_routes")[verb]
          end
          
          private
          
          def implied_verb? verb
            verb.in? :index, :create, :show, :update, :destroy
          end
          
          def raise_unless_setup_while_trying_to task
            raise "You have to call for(verb, entity) (and optionally within(parent)) on this HammockRoutePiece before you can #{task}." unless setup?
          end
          
        end
        
        DefaultRecordVerbs = {
          :show => :get,
          :edit => :get,
          :update => :put,
          :destroy => :delete
        }.freeze
        DefaultResourceVerbs = {
          :index => :get,
          :new => :get,
          :create => :post
        }.freeze

        attr_reader :mdl, :parent, :children, :record_routes, :resource_routes

        def initialize entity = nil, options = {}
          @mdl = entity if entity.is_a?(Symbol)
          @parent = options[:parent]
          @children = {}
          define_routes options
        end

        def ancestry
          parent.nil? ? [] : parent.ancestry.push(self)
        end

        def for verb, entities, options
          raise "HammockResource#for requires an explicitly specified verb as its first argument." unless verb.is_a?(Symbol)
          raise "You have to supply at least one record or resource." if entities.empty?

          entity = entities.shift

          if entities.empty?
            piece_for verb, entity
          else
            children[entity.resource_sym].for(verb, entities, options).within piece_for(nil, entity)
          end
        end

        def add entity, options, steps = nil
          if steps.nil?
            add entity, options, (options[:name_prefix] || '').chomp('_').split('_').map {|i| i.pluralize.underscore.to_sym }
          elsif steps.empty?
            add_child entity, options
          else
            children[steps.shift].add entity, options, steps
          end
        end

        def routeable_as verb, entity
          if entity.record? && record_routes[verb || :show]
            :record
          elsif entity.resource? && resource_routes[verb || :index]
            :resource
          end
        end

        private

        def define_routes options
          @record_routes = DefaultRecordVerbs.dup.update(options[:member] || {})
          @resource_routes = DefaultResourceVerbs.dup.update(options[:collection] || {})
        end

        def add_child entity, options
          child = HammockResource.new entity, options.merge(:parent => self)
          children[child.mdl] = child
        end

        def piece_for verb, entity
          child = children[entity.resource_sym]

          if child.nil?
            raise "No routes are defined for #{entity.route_map}#{' within ' + ancestry.map {|r| r.mdl.to_s }.join(', ') unless ancestry.empty?}."
          else
            HammockRoutePiece.new(child).for(verb, entity)
          end
        end

      end

    end
  end
end
