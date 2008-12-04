module Hammock
  module Utils
    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      base.class_eval {
        helper_method :partial_exists?
      }
    end

    module ClassMethods

    end

    module InstanceMethods
      private

      def partial_exists? name, extension = nil
        partial_name, ctrler_name = name.split('/', 2).reverse
        !Dir.glob(File.join(RAILS_ROOT, 'app/views', ctrler_name || '', "_#{partial_name}.html.#{extension || '*'}")).empty?
      end

      def redirect_back_or path = nil
        if request.referer.blank?
          redirect_to path || root_path
        else
          redirect_to request.referer
        end
      end

      def rendered_or_redirected?
        @performed_render || @performed_redirect
      end

    end
  end
end
