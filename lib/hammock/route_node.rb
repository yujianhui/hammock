module Hammock
  class RouteNode < ActionController::Resources::Resource

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
        @routing_parent = determine_routing_parent
        define_routes options
      end
    end

    def resource
      # TODO performance
      Object.const_get mdl.to_s.classify rescue nil
    end

    def root?
      parent.nil?
    end

    def ancestry
      root? ? [] : parent.ancestry.push(self)
    end

    def for verb, entities, options
      raise "Hammock::RouteNode#for requires an explicitly specified verb as its first argument." unless verb.is_a?(Symbol)
      raise "Hammock::RouteNode#for requires an Array of at least one record or resource." if entities.empty? || !entities.is_a?(Array)

      entity = entities.shift

      if entities.empty?
        steps_for verb, entity
      else
        children[entity.resource_sym].for(verb, entities, options).within steps_for(nil, entity)
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

    def nesting_scope_list_for params
      if root?
        [ ]
      else
        parent.nesting_scope_list_for(params).push nesting_scope_segment_for(params)
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
      # puts "\ndetermine_routing_parent: #{mdl}:"
      if parent.nil? || parent.resource.nil?
        # puts "Resource for #{mdl} has either no parent or no resource - not nestable."
        nil
      else
        # puts "reflections: #{resource.reflections.keys.inspect}"
        scannable_reflections = resource.nestable_routing_resources.nil? ? resource.reflections : resource.reflections.dragnet(*resource.nestable_routing_resources)
        # puts "scannable reflections: #{scannable_reflections.keys.inspect}"
        valid_reflections = scannable_reflections.selekt {|k,v|
          # puts "#{v.klass}<#{v.object_id}> == #{parent.resource}<#{parent.resource.object_id}> #=> #{v.klass == parent.resource}"
          v.klass == parent.resource
        }
        # puts "valid reflections: #{valid_reflections.keys.inspect}"

        if valid_reflections.keys.length < 1
          raise "The routing table specifies that #{mdl} is nested within #{parent.mdl}, but there is no ActiveRecord association linking #{resource} to #{parent.resource}. Example: 'belongs_to :#{parent.resource.base_model}' in the #{resource} model."
        elsif valid_reflections.keys.length > 1
          raise "#{resource} defines more than one association to #{parent.resource} (#{valid_reflections.keys.map(&:to_s).join(', ')}). That's fine, but you need to use #{resource}.nest_within to specify the one Hammock should nest scopes through. For example, 'nest_within #{valid_reflections.keys.first.inspect}' in the #{resource} model."
        # else
          # puts "Routing #{mdl} within #{valid_reflections.keys.first} (chose from #{scannable_reflections.inspect})"
        end

        valid_reflections.keys.first
      end
    end

    def add_child entity, options
      child = RouteNode.new entity, options.merge(:parent => self)
      children[child.mdl] = child
    end

    def steps_for verb, entity
      child = children[entity.resource_sym]

      if child.nil?
        raise "No routes are defined for #{entity.resource}#{' within ' + ancestry.map {|r| r.mdl.to_s }.join(', ') unless ancestry.empty?}."
      else
        RouteStep.new(child).for(verb, entity)
      end
    end

  end
end
