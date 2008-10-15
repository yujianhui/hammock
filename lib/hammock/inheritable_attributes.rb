module Hammock
  module InheritableAttributes
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def nestable_by resources
        write_inheritable_attribute :nestable_by, resources
      end

      def inline_create
        write_inheritable_attribute :inline_create, true
      end

      def find_on_create
        write_inheritable_attribute :find_on_create, true
      end

      def find_column column_name
        write_inheritable_attribute :find_column, column_name
      end
    end

    module InstanceMethods

      private

      def nestable_resources
        self.class.read_inheritable_attribute(:nestable_by) || {}
      end

      def inline_createable_resource?
        self.class.read_inheritable_attribute :inline_create
      end

      def findable_on_create?
        self.class.read_inheritable_attribute :find_on_create
      end

      def find_column_name
        self.class.read_inheritable_attribute(:find_column) || :id
      end
    end
  end
end
