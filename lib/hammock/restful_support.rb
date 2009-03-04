module Hammock
  module RestfulSupport
    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      base.class_eval {
        before_modify :set_editing
        # TODO Investigate the usefulness of this.
        # before_destroy :set_editing
        before_create :set_creator_id_if_appropriate
        helper_method :mdl, :mdl_name, :editing?, :nested_within?, :partial_exists?
      }
    end

    module ClassMethods

    end

    module InstanceMethods
      private

      # The model this controller operates on. Defined as the singularized controller name. For example, for +GelatinousBlobsController+, this will return the +GelatinousBlob+ class.
      def mdl
        @hammock_cached_mdl ||= Object.const_get self.class.to_s.sub('Controller', '').classify
      end
      # The lowercase name of the model this controller operates on. For example, for +GelatinousBlobsController+, this will return "gelatinous_blob".
      def mdl_name
        @hammock_cached_mdl_name ||= self.class.to_s.sub('Controller', '').singularize.underscore
      end

      # Returns the node in the Hammock routing map corresponding to the (possibly nested) resource handling the current request.
      def current_hammock_resource
        nesting_resources = params.keys.select {|k| /_id$/ =~ k }.map {|k| k.gsub(/_id$/, '').pluralize }
        ActionController::Routing::Routes.route_map.base_for nesting_resources.push(mdl.resource_name).map(&:to_sym)
      end

      # Returns true if the current action represents an edit on +record+.
      #
      # For example, consider the route <tt>/articles/3/comments/31/edit</tt>, which fires <tt>CommentsController#edit</tt>. The nested route handler would assign <tt>@comment</tt> and <tt>@article</tt> to the appropriate records, and then the following would be observed:
      #   editing?(@comment) #=> true
      #   editing?(@article) #=> false
      def editing? record
        record == @editing
      end

      # Returns <tt>params[key]</tt>, defaulting to an empty Hash if <tt>params[key]</tt> can't receive :[].
      #
      # This is useful for concise nested parameter access. For example, if <tt>params[:account]</tt> is nil:
      #   params[:account][:email]      #=> NoMethodError: undefined method `[]' for nil:NilClass
      #   params_for(:account)[:email]  #=> nil
      def params_for key
        params[key] || {}
      end

      def assign_entity record_or_records
        @entity = if record_or_records.nil?
          # Fail
        elsif record_or_records.is_a? ActiveRecord::Base
          instance_variable_set "@#{mdl_name}", (@record = record_or_records)
        elsif record_or_records.is_a? Ambition::Context
          log "Unkicked query: #{record_or_records.to_hash.inspect}"
          instance_variable_set "@#{mdl_name.pluralize}", (@records = record_or_records)
        elsif record_or_records.is_a? Array
          instance_variable_set "@#{mdl_name.pluralize}", (@records = record_or_records)
        else
          raise "Unknown record(s) type #{record_or_records.class}."
        end

        if assign_nestable_resources
          @entity
        else
          escort :not_found
        end
      end

      private

      def make_new_record resource = mdl
        resource.new_with(params_for(resource.symbolize))
      end

      def assign_createable
        assign_entity make_createable
      end

      def make_createable resource = mdl
        if !(new_record = make_new_record(resource))
          log "Couldn't create a new #{resource.base_model} with the given nesting level and parameters."
        elsif !new_record.createable_by?(@current_account)
          log "#{requester_name} can't create #{new_record.resource_name}."
        else
          new_record
        end
      end

      def assign_nestable_resources
        @current_nested_records, @current_nested_resources = [], []
        params.symbolize_keys.dragnet(*nestable_resources.keys).all? {|param_name,column_name|
          constant_name = param_name.to_s.sub(/_id$/, '').camelize
          constant = Object.const_get constant_name rescue nil

          if constant.nil?
            log "'#{constant_name}' is not available for #{param_name}."
          elsif (record = constant.find_by_id(params[param_name])).nil?
            log "#{constant}<#{params[param_name]}> not found."
          else
            @current_nested_records << record
            @current_nested_resources << record.class
            @record.send "#{nestable_resources[param_name]}=", params[param_name] unless @record.nil?
            # log "Assigning @#{constant.name.underscore} with #{record.inspect}."
            instance_variable_set "@#{constant_name.underscore}", record
          end
        }
      end

      def current_nested_records
        (@current_nested_records || []).dup
      end

      def current_nested_resources
        (@current_nested_resources || []).dup
      end

      def add_nested_entity entity
        (@current_nested_records ||= []).push entity
        (@current_nested_resources ||= []).push entity.resource
      end

      def nested_within? record_or_resource
        if record_or_resource.is_a? ActiveRecord::Base
          current_nested_records.include? record_or_resource
        else
          current_nested_resources.include? record_or_resource
        end
      end

      def safe_verb_and_implication?
        request.get? && !action_name.to_s.in?(Hammock::Constants::ImpliedUnsafeActions)
      end

      def set_editing
        @editing = @record
      end

      # TODO process /^creating_\w+_id$/ as well
      def set_creator_id_if_appropriate
        if @record.respond_to?(:creator_id=)
          if @current_account.nil?
            log "Warning: @#{@record.base_model}.creator_id isn't being set, since @current_account was nil."
          else
            @record.creator_id = @current_account.id
          end
        end
      end

      def partial_exists? name, extension = nil
        partial_name, ctrler_name = name.split('/', 2).reverse
        !Dir.glob(File.join(
          RAILS_ROOT,
          'app/views',
          ctrler_name || '',
          "_#{partial_name}.html.#{extension || '*'}"
        )).empty?
      end

      def redirect_back_or opts = {}, *parameters_for_method_reference
        if request.referer.blank?
          redirect_to opts, *parameters_for_method_reference
        else
          redirect_to request.referer
        end
      end

      def rendered_or_redirected?
        @performed_render || @performed_redirect
      end

    end
  end
end
