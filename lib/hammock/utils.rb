module Hammock
  module Utils
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      base.class_eval {
        helper_method :partial_exists?
      }
    end

    module ClassMethods

    end

    module InstanceMethods

      def partial_exists? name, extension = nil
        !Dir.glob(File.join(RAILS_ROOT, 'app/views', controller_name, "_#{name}.html.#{extension || '*'}")).empty?
      end

      def redirect_back_or path = nil
        if request.referer.blank?
          redirect_to path || root_path
        else
          redirect_to request.referer
        end
      end

      def development?
        'development' == ENV['RAILS_ENV']
      end

    end
  end
end
