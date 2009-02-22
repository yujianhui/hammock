module Hammock
  module ActiveRecordPatches
    MixInto = ActiveRecord::Base

    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods # TODO maybe include in the metaclass instead of extending the class?

      %w[before_undestroy after_undestroy].each {|callback_name|
        MixInto.define_callbacks callback_name
        # base.send :define_method, callback_name, lambda { }
      }
    end

    module ClassMethods

      def new_with attributes
        default_attributes.merge(attributes).inject(new) {|record,(k,v)|
          record.send "#{k}=", v
          record
        }
      end

      def sorter
        # TODO updated_at DESC
        proc {|record| record.id }
      end

      def resource
        base_class
      end

      def resource_sym
        resource_name.to_sym
      end

      def resource_name
        # TODO almost certainly a better way to do this
        base_class.to_s.pluralize.underscore
      end

      def base_model
        base_class.to_s.underscore
      end

      def record?; false end
      def resource?; true end

      def update_statement set_clause, where_clause
        statement = "UPDATE #{table_name} SET #{set_clause} WHERE #{send :sanitize_sql_array, where_clause}"
        connection.update statement
      end

      def reset_cached_column_info
        reset_column_information
        subclasses.each &:reset_cached_column_info
      end
      
      def find_or_new_with(find_attributes, create_attributes = {})
        finder = respond_to?(:find_with_deleted) ? :find_with_deleted : :find

        if record = send(finder, :first, :conditions => find_attributes.discard(:deleted_at))
          # Found the record, so we can return it, if:
          # (a) the record can't have a stored deletion state,
          # (b) it can, but it's not actually deleted,
          # (c) it is deleted, but we want to find one that's deleted, or
          # (d) we don't want a deleted record, and undestruction succeeds.
          if (finder != :find_with_deleted) || !record.deleted? || create_attributes[:deleted_at] || record.undestroy
            record
          end
        else
          creating_class = if create_attributes[:type].is_a?(ActiveRecord::Base)
            create_attributes.delete(:type)
          else
            self
          end
          creating_class.new_with create_attributes.merge(find_attributes)
        end
      end

      def find_or_create_with(find_attributes, create_attributes = {}, adjust_attributes = false)
        if record = find_or_new_with(find_attributes, create_attributes)
          log "Create failed. #{record.errors.inspect}", :skip => 1 if record.new_record? && !record.save
          log "Adjust failed. #{record.errors.inspect}", :skip => 1 if adjust_attributes && !record.adjust(create_attributes)
          record
        end
      end
      
      # def find_or_create_with! find_attributes, create_attributes = {}, adjust_attributes = false)
      #   record = find_or_new_with find_attributes, create_attributes, adjust_attributes
      #   record.valid? ? record : raise("Save failed. #{record.errors.inspect}")
      # end

    end

    module InstanceMethods

      def concise_inspect
        "#{self.class}<#{self.id || 'new'}>"
      end

      def resource
        self.class.resource
      end

      def resource_sym
        self.class.resource_sym
      end

      def resource_name
        self.class.resource_name
      end

      def record?; true end
      def resource?; false end

      def id_str
        if new_record?
          "new_#{base_model}"
        else
          "#{base_model}_#{id}"
        end
      end

      def id_or_description
        new_record? ? new_record_description : id
      end
      
      def new_record_description
        attributes.map {|k,v| "#{k}-#{(v.to_s || '')[0..10]}" }.join("_")
      end

      def base_model
        self.class.base_model
      end

      def new_or_deleted_before_save?
        @new_or_deleted_before_save
      end
      def set_new_or_deleted_before_save
        @new_or_deleted_before_save = new_record? || send_if_respond_to(:deleted?)
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

      # Updates each given attribute to the current time.
      #
      # Assumes that each column can accept a +Time+ instance, i.e. that they're all +datetime+ columns or similar.
      #
      # The updates are done with update_attribute, and as such they are done with callbacks but
      # without validation.
      def touch *attrs
        now = Time.now
        attrs.each {|attribute|
          update_attribute attribute, now
        }
      end

      # Updates each given attribute to the current time, skipping attributes that are already set.
      #
      # Assumes that each column can accept a +Time+ instance, i.e. that they're all +datetime+ columns or similar.
      #
      # The updates are done with update_attribute, and as such they are done with callbacks but
      # without validation.
      def touch_once *attrs
        touch *attrs.select {|attribute| attributes[attribute.to_s].nil? }
      end

      def adjust attrs
        attrs.each {|k,v| send "#{k}=", v }
        save false
      end

      def unsaved_attributes
        self.changed.inject({}) {|hsh,k|
          hsh[k] = attributes[k]
          hsh
        }
      end

      # Offset +attribute+ by +offset+ atomically in SQL.
      def offset! attribute, offset
        if new_record?
          log "Can't offset! a new record."
        else
          # Update the in-memory model
          send "#{attribute}=", send(attribute) + offset
          # Update the DB
          run_updater_sql 'Offset', "#{connection.quote_column_name(attribute)} = #{connection.quote_column_name(attribute)} + #{quote_value(offset)}"
        end
      end


      private

      def run_updater_sql logger_prefix, set_clause
        connection.update(
          "UPDATE #{self.class.table_name} " +
          "SET #{set_clause} " +
          "WHERE #{connection.quote_column_name(self.class.primary_key)} = #{quote_value(id)}",

          "#{self.class.name} #{logger_prefix}"
        ) != false
      end

      # TODO Use ambition for association queries.
      # def self.collection_reader_method reflection, association_proxy_class
      #   define_method(reflection.name) do |*params|
      #     reflection.klass.ambition_context.select { |entity| entity.__send__(reflection.primary_key_name) == quoted_id }
      #   end
      # end

    end
  end
end
