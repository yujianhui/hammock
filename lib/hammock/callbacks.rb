module Hammock
  module Callbacks
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      base.class_eval {
        include ActiveSupport::Callbacks

        define_callbacks *%w{
          during_find

          before_index     before_show
          before_modify    before_new      before_edit

          before_save      after_save
          before_create    after_create
          before_update    after_update
          before_destroy   after_destroy
          before_undestroy after_undestroy
        }
      }
    end

    module ClassMethods
    end

    module InstanceMethods
      private

      def callback kind, *args
        chain = self.class.send "#{kind}_callback_chain"

        if chain.empty?
          debug "No #{kind} callbacks to run."
          true
        else
          debug "Running #{kind} callbacks."
          chain.all? {|cb|
            debug "calling #{cb.method}"
            result = cb.call(self, *args) != false
            log "  #{self.class}.#{cb.kind} callback '#{cb.method}' failed." unless result
            result
          }
        end
      end

    end
  end
end
