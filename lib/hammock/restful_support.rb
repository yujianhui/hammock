module Hammock
  module RestfulSupport
    def self.included base
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
        @_cached_table_name ||= self.class.to_s.sub('Controller', '').downcase
      end


      def make_new_record
        assign_named_record_instances mdl.new_with params_for mdl.symbolize
      end

      def assign_named_record_instances generic_instance
        if generic_instance.is_a? Array
          instance_variable_set "@#{table_name}", (@records = generic_instance)
        else
          instance_variable_set "@#{mdl_name}", (@record = generic_instance)
        end
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

      def debug message
        logger.info message if 'development' == ENV['RAILS_ENV']
      end

    end
  end
end
