module Hammock
  module ActionControllerPatches
    MixInto = ActionController::Rescue

    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
      
      base.class_eval {
        alias_method_chain :clean_backtrace, :truncation
      }
    end

    module ClassMethods

    end

    module InstanceMethods

      private

      def clean_backtrace_with_truncation exception
        if backtrace = clean_backtrace_without_truncation(exception)
          backtrace.take_while {|line|
            line['perform_action_without_filters'].nil?
          }.push("... and so on")
        end
      end

    end
  end
end
