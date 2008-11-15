module Hammock
  module ModelAttributes
    MixInto = ActiveRecord::Base
    
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods

      def has_defaults attrs
        write_inheritable_attribute "default_attributes", (default_attributes || {}).merge(attrs)
      end
      def attr_accessible_on_create *attributes
        write_inheritable_attribute "attr_accessible_on_create", Set.new(attributes.map(&:to_s)) + (accessible_attributes_on_create || [])
      end
      def attr_accessible_on_update *attributes
        write_inheritable_attribute "attr_accessible_on_update", Set.new(attributes.map(&:to_s)) + (accessible_attributes_on_update || [])
      end

      def default_attributes
        read_inheritable_attribute("default_attributes") || {}
      end
      def accessible_attributes_on_create
        read_inheritable_attribute "attr_accessible_on_create"
      end
      def accessible_attributes_on_update
        read_inheritable_attribute "attr_accessible_on_update"
      end

    end

    module InstanceMethods

    end
  end
end
