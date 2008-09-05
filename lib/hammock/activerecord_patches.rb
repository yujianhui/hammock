module Hammock
  module ActiveRecordPatches
    MixInto = ActiveRecord::Base
    
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods # TODO maybe include in the metaclass instead of extending the class?
      
      # base.class_eval {
      #   export_scopes base
      # }
    end

    module ClassMethods

      def export_scope verb, as = nil
        verbable_by = "#{as || verb}able_by"

        if !(respond_to?("#{verb}_scope_for") ^ respond_to?("#{verb}_scope"))
          raise "You have to define either #{name}.#{verb}_scope or #{name}.#{verb}_scope_for(account), but not both, to export the '#{verb}' scope."
        elsif respond_to?("#{verb}_scope_for")
          class << self; self end.instance_eval {
            define_method verbable_by do |account|
              select &send("#{verb}_scope_for", account)
            end
          }
          define_method "#{verbable_by}?" do |account|
            self.class.send("#{verb}_scope_for", account).call(self)
          end
        else
          class << self; self end.instance_eval {
            define_method verbable_by do |account|
              select &send("#{verb}_scope")
            end
          }
          define_method "#{verbable_by}?" do |account|
            self.class.send("#{verb}_scope").call(self)
          end
        end
      end

      def reset_cached_column_info
        reset_column_information
        reset_inheritable_attributes
        reset_column_information_and_inheritable_attributes_for_all_subclasses
      end
    end

    module InstanceMethods

      def concise_inspect
        "#{self.class}<#{self.id || 'new'}>"
      end

      def self.base_model
        base_class.to_s.underscore
      end

      def base_model
        self.class.base_model
      end

      # TODO acts_as_paranoid or similar.
      def deleted?
        false
      end

      private

      # def self.collection_reader_method reflection, association_proxy_class
      #   define_method(reflection.name) do |*params|
      #     reflection.klass.ambition_context.select { |entity| entity.__send__(reflection.primary_key_name) == quoted_id }
      #   end
      # end

    end
  end
end
