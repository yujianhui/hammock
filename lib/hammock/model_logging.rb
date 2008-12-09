module Hammock
  module ModelLogging
    MixInto = ActiveRecord::Base

    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
      include Hammock::Utils::Methods
      include Hammock::Logging::Methods
    end

    module InstanceMethods
      include Hammock::Utils::Methods
      include Hammock::Logging::Methods

      def log_with_model *args
        opts = args.extract_options!

        message = "#{self.class}<#{self.id}>#{(' | ' + args.shift) if args.first.is_a?(String)}"

        log_without_model *args.unshift(message).push(opts.merge(:skip => (opts[:skip] || 0) + 1))
      end
      alias_method_chain :log, :model

    end
  end
end
