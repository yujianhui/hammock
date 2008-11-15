module Hammock
  # TODO This file is horribly non-DRY.
  module CannedScopes
    MixInto = ActiveRecord::Base

    # TODO Put this somewhere better.
    StandardVerbs = [:read, :write, :index]

    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods

      protected

      def public_resource
        public_scope_for *StandardVerbs
      end

      def creator_resource
        creator_scope_for *StandardVerbs
      end

      def partitioned_resource
        partitioned_resource_for *StandardVerbs
      end

      def creator_resource_for *verbs
        verbs = StandardVerbs if verbs.blank?
        metaclass.instance_eval {
          verbs.each {|verb|
            puts "defining #{verb}_scope on #{self}"
            send :define_method, "#{verb}_scope_for" do |account|
              lambda {|record| record.creator_id == account.id }
            end
          }
        }
        export_scopes *verbs
      end

      def public_resource_for *verbs
        verbs = StandardVerbs if verbs.blank?
        metaclass.instance_eval {
          verbs.each {|verb|
            puts "defining #{verb}_scope on #{self}"
            send :define_method, "#{verb}_scope" do
              lambda {|record| true }
            end
          }
        }
        export_scopes *verbs
      end

      def partitioned_resource_for *verbs
        verbs = StandardVerbs if verbs.blank?
        metaclass.instance_eval {
          verbs.each {|verb|
            puts "defining #{verb}_scope on #{self}"
            send :define_method, "#{verb}_scope_for" do |account|
              lambda {|record| record.id == account.id }
            end
          }
        }
        export_scopes *verbs
      end

    end

    module InstanceMethods

    end
  end
end
