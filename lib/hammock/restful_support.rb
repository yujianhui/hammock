module Hammock
  module RestfulSupport
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      base.class_eval {
        before_modify :set_editing
        helper_method :mdl, :mdl_name, :table_name, :editing?, :partial_exists?, :log, :dlog
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
      
      def make_new_record
        assign_resource mdl.new params_for mdl.symbolize
      end

      def assign_resource record_or_records
        if record_or_records.nil?
          # Fail
        elsif record_or_records.is_a? ActiveRecord::Base
          instance_variable_set "@#{mdl_name}", (@record = record_or_records)
        elsif record_or_records.is_a? Ambition::Context
          log "Unkicked query: #{record_or_records.to_s}"
          instance_variable_set "@#{table_name}", (@records = record_or_records)
        elsif record_or_records.is_a? Array
          instance_variable_set "@#{table_name}", (@records = record_or_records)
        else
          raise "Unknown record(s) type #{record_or_records.class}."
        end
      end

      def safe_action_and_implication? action = nil
        request.get? && %w{ index show }.include?((action || action_name).to_s)
      end

      def action_requires_record? action
        %{ show edit update delete }.include?(action.to_s)
      end

      def set_editing
        @editing = @record.class.symbolize
      end

      def partial_exists? name, extension = nil
        !Dir.glob(File.join(RAILS_ROOT, 'app/views', controller_name, "_#{name}.html.#{extension || '*'}")).empty?
      end

      def editing? record
        record.class.symbolize == @editing
      end

      def params_for key
        params[key] || {}
      end

      def development?
        'development' == ENV['RAILS_ENV']
      end
      
      # TODO move to authentication when that's included in hammock.
      def returning_login_path
        session[:path_after_login] = request.request_uri
        login_path
      end

    end
  end
end
