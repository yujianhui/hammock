module Hammock
  module InheritableAttributes
    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods

      # Specifies parent resources that can appear above this one in the route, and will be applied as an extra scope condition whenever present.
      #
      # Supplied as a hash of parameter names to attribute names. For example, given the route <tt>/accounts/7/posts/31</tt>,
      #     nestable_by :account_id => :creator_id
      # Would add an extra scope condition requiring that <tt>@post.creator_id</tt> == <tt>params[:account_id]</tt>.
      def nestable_by resources
        write_inheritable_attribute :nestable_by, resources
      end

      # When +inline_create+ is specified for a controller, the +index+ page will have the ability to directly create new resources, just as the +new+ page normally can.
      #
      # To use +inline_create+, refactor the relevant contents of your +new+ view into a partial and render it in an appropriate place within the +index+ view.
      #
      # A successful +create+ will redirect to the +show+ action for the new record, and a failed +create+ will re-render the +index+ action with a populated form, in the same way the +new+ action would normally be rendered in the event of a failed +create+.
      def inline_create
        write_inheritable_attribute :inline_create, true
      end

      # When +find_on_create+ is specified for a controller, attempts to +create+ new records will first check to see if an identical record already exists. If such a record is found, it is returned and the create is never attempted.
      #
      # This is useful for the management of administrative records like memberships or friendships, where the user may attempt to create a new record using some unique identifier like an email address. For such a resource, a pre-existing record should not be considered a failure, as would otherwise be triggered by uniqueness checks on the model.
      def find_on_create &proc
        write_inheritable_attribute :find_on_create, true
        write_inheritable_attribute :find_on_create_proc, proc
      end

      # Use +find_column+ to specify the name of an alternate column with which record lookups should be performed.
      #
      # This is useful for controllers that are indexed by primary key, but are accessed with URLs containing some other unique attribute of the resource, like a randomly-generated key.
      #     find_column :key
      def find_column column_name
        write_inheritable_attribute :find_column, column_name
      end
    end

    module InstanceMethods
      def nestable_resources
        self.class.read_inheritable_attribute(:nestable_by) || {}
      end

      def inline_createable_resource?
        self.class.read_inheritable_attribute :inline_create
      end

      def findable_on_create?
        self.class.read_inheritable_attribute :find_on_create
      end
      def find_on_create_proc
        self.class.read_inheritable_attribute :find_on_create_proc
      end

      def find_column_name
        self.class.read_inheritable_attribute(:find_column) || :id
      end
    end
  end
end
