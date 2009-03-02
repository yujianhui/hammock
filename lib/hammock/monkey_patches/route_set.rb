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
            elsif (:build == routeable_as) && entity.record? && !entity.new_record?
              raise "The verb '#{verb}' requires either the #{entity.resource} resource, or a #{entity.resource} without an ID (i.e. a new record)."
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
          
          def path params = nil
            raise_unless_setup_while_trying_to 'render a path'

            buf = '/'
            buf << entity.resource_name
            buf << '/' + entity.to_param if entity.record? && !entity.new_record?
            buf << '/' + verb.to_s unless verb.nil? or implied_verb?(verb)

            buf = parent.path + buf unless parent.nil?
            buf << param_str(params)

            buf
          end
          
          def http_method
            raise_unless_setup_while_trying_to 'extract the HTTP method'
            resource.send("#{routeable_as}_routes")[verb]
          end
          
          def fake_http_method
            http_method.in?(:get, :post) ? http_method : :post
          end

          def get?;       :get == http_method end
          def post?;     :post == http_method end
          def put?;       :put == http_method end
          def delete?; :delete == http_method end

          def safe?
            get? && !verb.in?(Hammock::Constants::ImpliedUnsafeActions)
          end

          private
          
          def implied_verb? verb
            verb.in? :index, :create, :show, :update, :destroy
          end
          
          def raise_unless_setup_while_trying_to task
            raise "You have to call for(verb, entity) (and optionally within(parent)) on this HammockRoutePiece before you can #{task}." unless setup?
          end
          
          def param_str params
            link_params = entity.record? ? entity.unsaved_attributes.merge(params || {}) : params

            if link_params.blank?
              ''
            else
              '?' + {entity.base_model => link_params}.to_query
            end
          end

        end
        
        DefaultRecordVerbs = {
          :show => :get,
          :edit => :get,
          :update => :put,
          :destroy => :delete
        }.freeze
        DefaultResourceVerbs = {
          :index => :get
        }.freeze
        DefaultBuildVerbs = {
          :new => :get,
          :create => :post
        }.freeze

        attr_reader :mdl, :resource, :parent, :children, :routing_parent, :record_routes, :resource_routes, :build_routes

        def initialize entity = nil, options = {}
          @parent = options[:parent]
          @children = {}
          unless root?
            @mdl = entity if entity.is_a?(Symbol)
            @resource = Object.const_get mdl.to_s.classify rescue nil
            @routing_parent = determine_routing_parent
            define_routes options
          end
        end

        def root?
          parent.nil?
        end

        def ancestry
          root? ? [] : parent.ancestry.push(self)
        end

        def for verb, entities, options
          raise "HammockResource#for requires an explicitly specified verb as its first argument." unless verb.is_a?(Symbol)
          raise "You have to supply an Array of at least one record or resource." if entities.empty? unless entities.is_a?(Array)

          entity = entities.shift

          if entities.empty?
            piece_for verb, entity
          else
            children[entity.resource_sym].for(verb, entities, options).within piece_for(nil, entity)
          end
        end

        def base_for resources
          # puts "base_for<#{mdl}>: resources=#{resources.inspect}."
          if resources.empty?
            self
          else
            match = nil
            children.values.detect {|child|
              # puts "  Trying #{child.ancestry.map(&:mdl).inspect} for #{resources.inspect}"
              if !resources.include?(child.mdl)
                # puts "  Can't match #{resources.inspect} against #{child.mdl}."
                nil
              else
                # puts "  Matched #{child.mdl} from #{resources.inspect}."
                match = child.base_for resources.discard(child.mdl)
              end
            } #|| raise("There is no routing path for #{resources.map(&:inspect).inspect}.")
            match
          end
        end

        def nesting_scope_for params
          if root?
            nil
          else
            segment = nesting_scope_segment_for params

            if parent.root?
              segment
            else
              segment.within parent.nesting_scope_for(params), routing_parent
            end
          end
        end

        def nesting_scope_segment_for params
          raise "The root of the route map isn't associated with a resource." if root?
          puts "is this undefined? #{resource.accessible_attributes_on_create.inspect}"
          value = params.delete resource.param_key
          puts "resource.select {|r| r.#{resource.routing_attribute} == value }"
          eval "resource.select {|r| r.#{resource.routing_attribute} == value }"
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
          elsif !verb.nil? && build_routes[verb]
            :build
          end
        end

        private

        def define_routes options
          @record_routes = DefaultRecordVerbs.dup.update(options[:member] || {})
          @resource_routes = DefaultResourceVerbs.dup.update(options[:collection] || {})
          @build_routes = DefaultBuildVerbs.dup.update(options[:build] || {})
        end

        def determine_routing_parent
          puts "\ndetermine_routing_parent: #{mdl}:"
          if parent.nil? || parent.resource.nil?
            puts "Resource for #{mdl} has either no parent or no resource - not nestable."
            nil
          else
            puts "reflections: #{resource.reflections.keys.inspect}"
            puts "nestable_routing_resources: #{resource.nestable_routing_resources.inspect}"
            scannable_reflections = resource.nestable_routing_resources.nil? ? resource.reflections : resource.reflections.dragnet(*resource.nestable_routing_resources)
            puts "scannable reflections: #{scannable_reflections.keys.inspect}"
            valid_reflections = scannable_reflections.selekt {|k,v| puts "#{v.klass}<#{v.object_id}> == #{parent.resource}<#{parent.resource.object_id}> #=> #{v.klass == parent.resource}"; v.klass == parent.resource }
            puts "valid reflections: #{valid_reflections.keys.inspect}"

            if valid_reflections.keys.length < 1
              raise "The routing table specifies that #{mdl} is nested within #{parent.mdl}, but there is no ActiveRecord association linking #{resource} to #{parent.resource}. Example: 'belongs_to :#{parent.resource.base_model}' in the #{resource} model."
            elsif valid_reflections.keys.length > 1
              raise "#{resource} defines more than one association to #{parent.resource} (#{valid_reflections.keys.map(&:to_s).join(', ')}). That's fine, but you need to use #{resource}.nest_within to specify the one Hammock should nest scopes through. For example, 'nest_within #{valid_reflections.keys.first.inspect}' in the #{resource} model."
            end

            valid_reflections.keys.first
          end
        end

        def add_child entity, options
          child = HammockResource.new entity, options.merge(:parent => self)
          children[child.mdl] = child
        end

        def piece_for verb, entity
          child = children[entity.resource_sym]

          if child.nil?
            raise "No routes are defined for #{entity.resource}#{' within ' + ancestry.map {|r| r.mdl.to_s }.join(', ') unless ancestry.empty?}."
          else
            HammockRoutePiece.new(child).for(verb, entity)
          end
        end

      end

    end
  end
end
