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

      def sqlite?
        'SQLite' == connection.adapter_name
      end

      def describe_call_point offset = 0
        "(called from #{call_point offset + 1})"
      end

      def call_point offset = 0
        caller[offset + 1].strip.gsub(rails_root, '').gsub(/\:in\ .*$/, '')
      end

    end
  end
end
