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
          _for(verb, args, opts).join(' / ')
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
            puts "ending #{verb}"
            [segment_for(verb, entity)]
          else
            puts "recursing #{verb}"
            puts entity.resource.to_s
            puts children.keys.map {|r| r.to_s }
            child = children[entities.first.resource]

            if child.nil?
              raise "Can't route #{entity.resource.base_model} from #{ancestry.map {|r| r.resource.mdl.to_s }}."
            else
              [segment_for(nil, entity)].concat child.send(:_for, verb, entities, opts)
            end
          end
        end
        
        def segment_for verb, entity
          puts "generating #{verb.inspect} #{entity.to_s}"

          if !routeable?(verb, entity)
            raise "The verb #{verb} can't be applied to the #{entity.resource} resource#{' or instances of it' if entity.is_a?(ActiveRecord::Base)}."
          else
            [
              entity.resource_name,
              (entity.to_param if entity.is_a?(ActiveRecord::Base)),
              (verb unless verb.nil? or implied_verb?(verb))
            ].squash.join('/')
          end
        end
        
        def routeable? verb, entity
          verb.nil? || resource_routes.has_key?(verb) || (entity.is_a?(ActiveRecord::Base) && record_routes.has_key?(verb))
        end

        def implied_verb? verb
          [ :index, :create, :show, :update, :destroy ].include? verb
        end
      end

    end
  end
end
