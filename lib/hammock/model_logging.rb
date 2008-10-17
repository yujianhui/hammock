module Hammock
  module ModelLogging
    MixInto = ActiveRecord::Base

    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      base.class_eval {
        alias_method_chain :log, :model
      }
    end

    module ClassMethods
      include Hammock::Logging::Methods
    end

    module InstanceMethods
      include Hammock::Logging::Methods

      def log_with_model *args
        opts = args.last.is_a?(Hash) ? args.pop : {}

        message = "#{self.class}<#{self.id}>#{(' | ' + args.shift) if args.first.is_a?(String)}"

        log_without_model *args.unshift(message).push(opts.merge(:skip => (opts[:skip] || 0) + 1))
      end

    end
  end
end