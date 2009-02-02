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
              raise "The verb #{verb} can't be applied to the #{entity.resource} resource#{' or instances of it' if entity.is_a?(ActiveRecord::Base)}."
            elsif (:record == routeable_as) && entity.new_record?
              raise "The verb #{verb} requires a #{entity.resource} that has an ID (i.e. not a new record)."
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
            buf << '/' + entity.to_param if entity.is_a?(ActiveRecord::Base)
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
          @mdl = Object.const_get(entity.to_s.classify) unless entity.nil?
          @parent = options[:parent]
          @children = {}
          define_routes options
        end

        def ancestry
          parent.nil? ? [] : parent.ancestry.push(self)
        end
        
        def for verb, *args
          opts = args.extract_options!
          raise "You have to supply at least one record or resource." if args.empty?
          _for verb, args, opts
        end

        def add entity, options, steps = nil
          if steps.nil?
            add entity, options, (options[:name_prefix] || '').chomp('_').split('_').map {|i| Object.const_get i.classify }
          elsif steps.empty?
            add_child entity, options
          else
            children[steps.shift].add entity, options, steps
          end
        end

        def routeable_as verb, entity
          if entity.is_a?(ActiveRecord::Base) && record_routes[verb || :show]
            :record
          elsif resource_routes[verb || :index]
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
          self.children[child.mdl] = child
        end

        def _for verb, entities, opts
          entity = entities.shift

          if entities.empty?
            piece_for verb, entity
          else
            children[entity.resource].send(:_for, verb, entities, opts).within piece_for(verb, entity)
          end
        end

        def piece_for verb, entity
          child = children[entity.resource]

          if child.nil?
            raise "Can't route #{entity.resource} within #{ancestry.map {|r| r.mdl.to_s }.join(', ')}."
          else
            HammockRoutePiece.new(child).for(verb, entity)
          end
        end

      end

    end
  end
end
