module Hammock
  module Scope
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      base.class_eval {
        helper_method :can_verb_entity?, :can_verb_resource?, :can_verb_record?
      }
    end

    module ClassMethods
    end

    module InstanceMethods

      def can_verb_entity? verb, entity
        if entity.is_a? ActiveRecord::Base
          can_verb_record? verb, entity
        else
          can_verb_resource? verb, entity
        end
      end

      def can_verb_resource? verb, resource
        if !resource.indexable_by(@current_account)
          log "#{requester_name} can't index #{resource.name.pluralize}."
          :not_found
        elsif !safe_action_and_implication?(verb) && !resource.createable_by(@current_account)
          log "#{requester_name} can't #{verb} #{resource.name.pluralize}."
          :read_only
        else
          # log "#{requester_name} can #{verb} #{resource.name.pluralize}."
          :ok
        end
      end

      def can_verb_record? verb, record
        if !record.readable_by?(@current_account)
          log "#{requester_name} can't see #{record.class}<#{record.id}>."
          :not_found
        elsif !safe_action_and_implication?(verb) && !record.writeable_by?(@current_account)
          log "#{requester_name} can't #{verb} #{record.class}<#{record.id}>."
          :read_only
        else
          # log "#{requester_name} can #{verb} #{record.class}<#{record.id}>."
          :ok
        end
      end

      def verb_scope
        if @current_account && (scope_name = account_verb_scope?)
          # log "got an account_verb_scope #{scope_name}."
          mdl.send scope_name, @current_account
        elsif !(scope_name = public_verb_scope?)
          log "No #{@current_account.nil? ? 'public' : 'account'} #{scope_name_for_action} scope available for #{mdl}.#{' May be available after login.' if account_verb_scope?}"
          nil
        else
          # log "got a #{scope_name} public_verb_scope."
          mdl.send scope_name
        end
      end

      def nest_scope
        params.symbolize_keys.dragnet(*nestable_resources.keys).inject(mdl.ambition_context) {|acc,(k,v)|
          # TODO this would be more ductile if it used AR assocs instead of explicit FK
          eval "acc.select {|r| r.#{nestable_resources[k]} == v }"
        }
      end

      def current_scope
        if (resultant_scope = nest_scope.chain(verb_scope)).nil?
          nil
        else
          resultant_scope.sort_by &mdl.sorter
        end
      end


      private

      def scope_name_for_action
        if 'index' == action_name
          'index'
        elsif safe_action_and_implication?
          'read'
        else
          'write'
        end
      end

      def requester_name
        @current_account.nil? ? 'Anonymous' : "#{@current_account.class}<#{@current_account.id}>"
      end

      def account_verb_scope?
        mdl.has_account_scope? scope_name_for_action
      end
      def public_verb_scope?
        mdl.has_public_scope? scope_name_for_action
      end

    end
  end
end
