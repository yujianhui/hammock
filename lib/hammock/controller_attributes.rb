module Hammock
  module ControllerAttributes
    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
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
      def find_on_create
        write_inheritable_attribute :find_on_create, true
      end
      
      def paginate_by per_page
        write_inheritable_attribute :pagination_enabled, true
        mdl.metaclass.instance_eval do
          define_method :per_page do
            per_page
          end
        end
      end
    end

    module InstanceMethods

      private

      def inline_createable_resource?
        self.class.read_inheritable_attribute :inline_create
      end

      def findable_on_create?
        self.class.read_inheritable_attribute :find_on_create
      end

      def pagination_enabled?
        self.class.read_inheritable_attribute :pagination_enabled
      end
    end
  end
end
