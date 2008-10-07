module Hammock
  module Callbacks
    LoadFirst = true

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

          before_suggest   after_suggest
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

        chain.all? {|cb|
          dlog "Calling #{kind} callback #{cb.method}"
          result = cb.call(self, *args) != false
          log "#{self.class}.#{cb.kind} callback '#{cb.method}' failed." unless result
          result
        }
      end

    end
  end
end
