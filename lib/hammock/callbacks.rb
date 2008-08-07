module Hammock
  module Callbacks
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      base.class_eval {
        include ActiveSupport::Callbacks

        define_callbacks *%w{
          before_find      during_find

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
      
      CallbackFail = false.freeze

      def callback kind, *args
        chain = self.class.send "#{kind}_callback_chain"

        if chain.empty?
          dlog "No #{kind} callbacks to run."
          true
        else
          dlog "Running #{kind} callbacks."
          chain.all? {|cb|
            dlog "Calling #{cb.method}"
            result = cb.call(self, *args) != false
            log "#{self.class}.#{cb.kind} callback '#{cb.method}' failed." unless result
            result
          }
        end
      end

    end
  end
end
