module Hammock
  module RestfulSupport
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      base.class_eval {
        before_modify :set_editing
        helper_method :mdl, :mdl_name, :table_name, :editing?, :log, :dlog
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
        @_cached_table_name ||= self.class.to_s.sub('Controller', '').underscore
      end
      
      def make_new_record
        assign_resource mdl.new params_for mdl.symbolize
      end

      def assign_resource record_or_records
        if record_or_records.nil?
          # Fail
        elsif record_or_records.is_a? ActiveRecord::Base
          log "assigned @record and @#{mdl_name}"
          instance_variable_set "@#{mdl_name}", (@record = record_or_records)
        # elsif record_or_records.is_a? Ambition::Context
        #   log "Unkicked query: #{record_or_records.to_s}"
        elsif record_or_records.is_a? Array
          log "assigned @records and @#{table_name}"
          instance_variable_set "@#{table_name}", (@records = record_or_records)
        else
          raise "Unknown record(s) type #{record_or_records.class}."
        end
      end

      def idempotent_action_and_implication? action
        request.get? && %w{ index show }.include?(action.to_s)
      end

      def action_requires_record? action
        %{ show edit update delete }.include?(action.to_s)
      end

      def set_editing
        @editing = @record.class.symbolize
      end

      def editing? record
        record.class.symbolize == @editing
      end

      def params_for key
        params[key] || {}
      end
      
      def log message
        logger.info message
      end
      
      def dlog message
        logger.info message if development?
      end
      
      def development?
        'development' == ENV['RAILS_ENV']
      end
    end
  end
end
