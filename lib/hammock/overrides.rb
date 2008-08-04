module Hammock
  module Overrides
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods

      def index_finder
        mdl.all
      end

      def inline_edit
        false
      end

      def postsave_redirect
        nil
      end

    end
  end
end
