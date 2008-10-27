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

          before_index     before_show     after_failed_show
          before_modify    before_new      before_edit

          before_save      after_save      after_failed_save
          before_create    after_create    after_failed_create
          before_update    after_update    after_failed_update
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
        callback_chain_for(kind).all? {|cb|
          # dlog "Calling #{kind} callback #{cb.method}"
          result = cb.call(self, *args) != false
          log "#{self.class}.#{cb.kind} callback '#{cb.method}' failed." unless result
          result
        }
      end

      def required_callback kind, *args
        callback(kind, *args) if has_callbacks_for?(kind)
      end

      def has_callbacks_for? kind
        !callback_chain_for(kind).empty?
      end

      def callback_chain_for kind
        self.class.send "#{kind}_callback_chain"
      end

    end
  end
end
