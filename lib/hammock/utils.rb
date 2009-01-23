module Hammock
  module Utils
    def self.included base # :nodoc:
      base.send :include, Methods
      base.send :extend, Methods
    end

    module Methods
      private

      require 'pathname'
      def rails_root
        @hammock_cached_rails_root ||= Pathname(RAILS_ROOT).realpath.to_s
      end

      def rails_env
        ENV['RAILS_ENV'] || 'development'
      end

      def development?
        'development' == rails_env
      end

      def production?
        'production' == rails_env
      end

    end
  end
end
