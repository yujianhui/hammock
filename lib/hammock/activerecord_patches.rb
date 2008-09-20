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

      def export_scope verb, opts = {}
        verbable = "#{opts[:as] || verb}able"

        if !(respond_to?("#{verb}_scope_for") ^ respond_to?("#{verb}_scope"))
          raise "You have to define either #{name}.#{verb}_scope or #{name}.#{verb}_scope_for(account), but not both, to export the '#{verb}' scope."
        elsif respond_to?("#{verb}_scope_for")
          class << self; self end.instance_eval {
            define_method "#{verbable}_by" do |account|
              select &send("#{verb}_scope_for", account)
            end
          }
          define_method "#{verbable}_by?" do |account|
            self.class.send("#{verb}_scope_for", account).call(self)
          end
        else
          class << self; self end.instance_eval {
            define_method verbable do
              select &send("#{verb}_scope")
            end
          }
          define_method "#{verbable}?" do
            self.class.send("#{verb}_scope").call(self)
          end
        end
      end

      def base_model
        base_class.to_s.underscore
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

      def base_model
        self.class.base_class.to_s.downcase
      end

      def undestroy
        unless new_record?
          if frozen?
            self.class.find_with_deleted(self.id).undestroy # Re-fetch ourselves and undestroy the thawed copy
          else
            # We can undestroy
            return false if callback(:before_undestroy) == false
            result = self.class.update_all ['deleted_at = ?', (self.deleted_at = nil)], ['id = ?', self.id]
            callback(:after_undestroy)
            self if result != false
          end
        end
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
