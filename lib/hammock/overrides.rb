module Hammock
  module Overrides
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods

      def finder_column
        :id
      end

      def index_finder
        if mdl.respond_to? :index_for
          mdl.index_for @current_account
        else
          mdl.all
        end
      end

      def inline_edit
        false
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
