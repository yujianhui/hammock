module Hammock
  module Overrides
    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods
      private

      def custom_scope
        nil
      end

      def suggest_scope
        mdl.readable_by current_user
      end

      def postsave_render result
        nil
      end

      def postsave_redirect
        nil
      end

      def postdestroy_redirect
        nil
      end

    end
  end
end
