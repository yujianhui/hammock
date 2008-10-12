module Hammock
  module RestfulSupport
    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      base.class_eval {
        before_modify :set_editing
        helper_method :mdl, :mdl_name, :table_name, :editing?
      }
    end

    module ClassMethods

    end

    module InstanceMethods

      def mdl
        @_cached_mdl ||= Object.const_get self.class.to_s.sub('Controller', '').singularize
      end
      def mdl_name
        @_cached_mdl_name ||= table_name.singularize
      end
      def table_name
        mdl.table_name
      end

      def editing? record
        record == @editing
      end

      def params_for key
        params[key] || {}
      end

      private

      def make_new_record
        assign_resource mdl.new params_for mdl.symbolize
      end

      def assign_resource record_or_records
        assignment = if record_or_records.nil?
          # Fail
        elsif record_or_records.is_a? ActiveRecord::Base
          instance_variable_set "@#{mdl_name}", (@record = record_or_records)
        elsif record_or_records.is_a? Ambition::Context
          # log "Unkicked query: #{record_or_records.to_s}"
          instance_variable_set "@#{table_name}", (@records = record_or_records)
        elsif record_or_records.is_a? Array
          instance_variable_set "@#{table_name}", (@records = record_or_records)
        else
          raise "Unknown record(s) type #{record_or_records.class}."
        end

        if assign_nestable_resources
          assignment
        else
          escort :not_found
        end
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

    end
  end
end
