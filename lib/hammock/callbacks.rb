module Hammock
  module Callbacks
    LoadFirst = true

    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      base.class_eval {
        include ActiveSupport::Callbacks

        define_hammock_callbacks *%w[
          before_find      during_find     after_failed_find

          before_index     before_show
          before_modify    before_new      before_edit

          before_save      after_save      after_failed_save
          before_create    after_create    after_failed_create
          before_update    after_update    after_failed_update
          before_destroy   after_destroy
          before_undestroy after_undestroy

          before_suggest   after_suggest
        ]
      }
    end

    module ClassMethods

      class HammockCallback < ActiveSupport::Callbacks::Callback
        private

        def evaluate_method method, *args, &block
          if method.is_a? Proc
            # puts "was a HammockCallback proc within #{args.first.class}."
            method.bind(args.shift).call(*args, &block)
          else
            super
          end
        end
      end

      def define_hammock_callbacks *callbacks
        callbacks.each do |callback|
          class_eval <<-"end_eval"
            def self.#{callback}(*methods, &block)
              callbacks = if !block_given? || methods.length > 1
                CallbackChain.build(:#{callback}, *methods, &block)
              else # hammock-style callback
                if methods.empty?
                  log "<-- you really should give this callback a description", :skip => 1
                elsif !methods.first.is_a?(String)
                  raise ArgumentError, "Inline callback definitions require a description as their sole argument."
                else
                  # logger.info "defining \#{methods.first} on \#{name} with method \#{block.inspect}."
                  [HammockCallback.new(:#{callback}, block, :identifier => methods.first)]
                end || []
              end
              # log callbacks
              (@#{callback}_callbacks ||= CallbackChain.new).concat callbacks
            end

            def self.#{callback}_callback_chain
              @#{callback}_callbacks ||= CallbackChain.new

              if superclass.respond_to?(:#{callback}_callback_chain)
                CallbackChain.new(superclass.#{callback}_callback_chain + @#{callback}_callbacks)
              else
                @#{callback}_callbacks
              end
            end
          end_eval
        end
      end

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
