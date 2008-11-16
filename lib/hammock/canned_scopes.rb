module Hammock
  # TODO This file is horribly non-DRY.
  module CannedScopes
    MixInto = ActiveRecord::Base

    # TODO Put this somewhere better.
    StandardVerbs = [:read, :write, :index, :create]

    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods

      protected

      def public_resource
        public_resource_for *StandardVerbs
      end

      def creator_resource
        creator_resource_for *StandardVerbs
      end

      def partitioned_resource
        partitioned_resource_for *StandardVerbs
      end

      def creator_resource_for *verbs
        verbs = StandardVerbs if verbs.blank?
        metaclass.instance_eval {
          verbs.each {|verb|
            send :define_method, "#{verb}_scope_for" do |account|
              creator_scope account
            end
          }
        }
        define_createable creator_scope if verbs.include?(:create)
        export_scopes *verbs
      end

      def public_resource_for *verbs
        verbs = StandardVerbs if verbs.blank?
        metaclass.instance_eval {
          verbs.each {|verb|
            send :define_method, "#{verb}_scope" do
              public_scope
            end
          }
        }
        define_createable public_scope if verbs.include?(:create)
        export_scopes *verbs
      end

      def partitioned_resource_for *verbs
        verbs = StandardVerbs if verbs.blank?
        metaclass.instance_eval {
          verbs.each {|verb|
            send :define_method, "#{verb}_scope_for" do |account|
              partitioned_scope account
            end
          }
        }
        define_createable partitioned_scope if verbs.include?(:create)
        export_scopes *verbs
      end

      def define_createable scope
        instance_eval {
          send :define_method, :createable_by? do |account|
            scope
          end
        }
      end

      # TODO This should be somewhere else
      def public_scope
        if sqlite?
          lambda {|record| 1 }
        else
          lambda {|record| true }
        end
      end
      
      def creator_scope account
        lambda {|record| record.creator_id == account.id }
      end
      
      def partitioned_scope account
        lambda {|record| record.id == account.id }
      end

      # TODO This should be somewhere else
      def sqlite?
        'SQLite' == connection.adapter_name
      end

    end

    module InstanceMethods

    end
  end
end
