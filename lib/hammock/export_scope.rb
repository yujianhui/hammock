module Hammock
  module ExportScope
    MixInto = ActiveRecord::Base

    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods

      def has_public_scope? scope_name
        "#{scope_name}able" if respond_to? "#{scope_name}_scope"
      end

      def has_account_scope? scope_name
        "#{scope_name}able_by" if respond_to? "#{scope_name}_scope_for"
      end

      def createable_by? account
        true
      end

      def export_scopes *verbs
        verbs.each {|verb| export_scope verb }
      end

      def export_scope verb
        verbable = "#{verb}able"

        metaclass.instance_eval {
          # Model.verbable_by: returns all records that are verbable by account.
          define_method "#{verbable}_by" do |account|
            if !account.nil? && respond_to?("#{verb}_scope_for")
              select &send("#{verb}_scope_for", account)
            elsif respond_to?("#{verb}_scope")
              select &send("#{verb}_scope")
            else
              select &all_scope
            end
          end

          # Model.verbable: returns all records that are verbable by anonymous users.
          define_method verbable do
            send "#{verbable}_by", nil
          end
        }

        # Model#verbable_by?: returns whether this record is verbable by account.
        define_method "#{verbable}_by?" do |account|
          if !account.nil? && self.class.respond_to?("#{verb}_scope_for")
            self.class.send("#{verb}_scope_for", account).call(self)
          elsif self.class.respond_to?("#{verb}_scope")
            self.class.send("#{verb}_scope").call(self)
          else
            true
          end
        end

        # Model#verbable?: returns whether this record is verbable by anonymous users.
        define_method "#{verbable}?" do
          send "#{verbable}_by?", nil
        end
      end
      
      def all_scope
        lambda {|record| true }
      end

      def none_scope
        lambda {|record| false }
      end

    end

    module InstanceMethods

      def createable_by? account
        true
      end

    end
  end
end
