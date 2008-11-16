module Hammock
  module RestfulSupport
    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      base.class_eval {
        before_modify :set_editing
        before_create :set_creator_id_if_appropriate
        helper_method :mdl, :mdl_name, :editing?
      }
    end

    module ClassMethods

    end

    module InstanceMethods

      # The model this controller operates on. Defined as the singularized controller name. For example, for +GelatinousBlobsController+, this will return the +GelatinousBlob+ class.
      def mdl
        @_cached_mdl ||= Object.const_get self.class.to_s.sub('Controller', '').singularize
      end
      # The lowercase name of the model this controller operates on. For example, for +GelatinousBlobsController+, this will return "gelatinous_blob".
      def mdl_name
        @_cached_mdl_name ||= self.class.to_s.sub('Controller', '').singularize.underscore
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

      def assign_resource record_or_records
        assignment = if record_or_records.nil?
          # Fail
        elsif record_or_records.is_a? ActiveRecord::Base
          instance_variable_set "@#{mdl_name}", (@record = record_or_records)
        elsif record_or_records.is_a? Ambition::Context
          # log "Unkicked query: #{record_or_records.to_s}"
          instance_variable_set "@#{mdl_name.pluralize}", (@records = record_or_records)
        elsif record_or_records.is_a? Array
          instance_variable_set "@#{mdl_name.pluralize}", (@records = record_or_records)
        else
          raise "Unknown record(s) type #{record_or_records.class}."
        end

        if assign_nestable_resources
          assignment
        else
          escort :not_found
        end
      end

      private

      def make_new_record
        assign_resource mdl.new_with params_for mdl.symbolize
      end

      def make_createable?
        make_new_record.createable_by? @current_account
      end

      def assign_nestable_resources
        @current_nested_records = []
        params.symbolize_keys.dragnet(*nestable_resources.keys).all? {|param_name,column_name|
          constant_name = param_name.to_s.sub(/_id$/, '').camelize
          constant = Object.const_get constant_name rescue nil

          if constant.nil?
            log "'#{constant_name}' is not available for #{param_name}."
          elsif (record = constant.find_by_id(params[param_name])).nil?
            log "#{constant}<#{params[param_name]}> not found."
          else
            @current_nested_records << record
            @record.send "#{nestable_resources[param_name]}=", params[param_name] unless @record.nil?
            # log "Assigning @#{constant.name.underscore} with #{record.inspect}."
            instance_variable_set "@#{constant_name.underscore}", record
          end
        }
      end

      def safe_action_and_implication? action = nil
        request.get? && %w{ index show }.include?((action || action_name).to_s)
      end

      def action_requires_record? action
        %{ show edit update delete }.include?(action.to_s)
      end

      def set_editing
        @editing = @record
      end

      def set_creator_id_if_appropriate
        @record.creator_id = @current_account.id if @record.respond_to?(:creator_id=)
      end

    end
  end
end
