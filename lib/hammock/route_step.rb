module Hammock
  class RouteStep
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
      raise "You have to call for(verb, entity) (and optionally within(parent)) on this RouteStep before you can #{task}." unless setup?
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
end
