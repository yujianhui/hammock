module Hammock
  module ActiveRecordPatches
    MixInto = ActiveRecord::Base
    
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
      
      # base.class_eval {
      #   export_scopes base
      # }
    end

    module ClassMethods

      def export_scope scope_name, opts = {}
        as = opts[:as] || scope_name

        if !(respond_to?("#{scope_name}_scope_for") ^ respond_to?("#{scope_name}_scope"))
          raise "You have to define either #{name}.#{scope_name}_scope or #{name}.#{scope_name}_scope_for(account), but not both, to export the '#{scope_name}' scope."
        elsif respond_to?("#{scope_name}_scope_for")
          class << self; self end.instance_eval {
            define_method as do |account|
              select &send("#{scope_name}_scope_for", account)
            end
          }
          define_method "#{as}?" do |account|
            self.class.send("#{scope_name}_scope_for", account).call(self)
          end
        else
          class << self; self end.instance_eval {
            define_method as do |account|
              select &send("#{scope_name}_scope")
            end
          }
          define_method "#{as}?" do |account|
            self.class.send("#{scope_name}_scope").call(self)
          end
        end
      end
      
      # def export_scopes base
      #   log "LOL EXPORTING SCOPES"
      #   log base.methods.grep(/extent/).inspect
      # end

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
