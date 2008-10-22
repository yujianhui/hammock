module Hammock
  module ActiveRecordPatches
    MixInto = ActiveRecord::Base

    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods # TODO maybe include in the metaclass instead of extending the class?
    end

    module ClassMethods

      def sorter
        # TODO updated_at DESC
        proc {|record| record.id }
      end

      def base_model
        base_class.to_s.underscore
      end

      def update_statement set_clause, where_clause
        statement = "UPDATE #{table_name} SET #{set_clause} WHERE #{send :sanitize_sql_array, where_clause}"
        connection.update statement
      end

      def reset_cached_column_info
        reset_column_information
        reset_column_information_and_inheritable_attributes_for_all_subclasses
      end
    end

    module InstanceMethods

      def concise_inspect
        "#{self.class}<#{self.id || 'new'}>"
      end

      def id_or_describer
        attributes.map {|k,v| "#{k}-#{(v.to_s || '')[0..10]}" }.join("_")
      end

      def base_model
        self.class.base_class.to_s.underscore
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

      def unsaved_attributes
        self.changed.inject({}) {|hsh,k|
          hsh[k] = attributes[k]
          hsh
        }
      end


      private

      # TODO Use ambition for association queries.
      # def self.collection_reader_method reflection, association_proxy_class
      #   define_method(reflection.name) do |*params|
      #     reflection.klass.ambition_context.select { |entity| entity.__send__(reflection.primary_key_name) == quoted_id }
      #   end
      # end

    end
  end
end
