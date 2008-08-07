module Hammock
  module ResourceRetrieval
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
      
      base.class_eval {
        helper_method :current_account_can_verb_record?
      }
    end

    module ClassMethods
    end

    module InstanceMethods
      
      def current_account_can_verb_record? verb, record
        if record.respond_to?(:visible_to?) && !record.visible_to?(@current_account)
          log "#{@current_account.class}<#{@current_account.id}> can't see #{record.class}<#{record.id}>."
          :unauthed
        elsif !idempotent_action_and_implication?(verb) && record.respond_to?(:editable_by?) && !record.editable_by?(@current_account)
          log "#{@current_account.class}<#{@current_account.id}> can't #{verb} #{record.class}<#{record.id}>."
          :read_only
        else
          log "#{@current_account.class}<#{@current_account.id}> can #{verb} #{record.class}<#{record.id}>."
          :ok
        end
      end

      def find_record opts = {}
        result = if !callback(:before_find)
          # callbacks failed
        elsif (record = retrieve_record(opts)).nil?
          :not_found
        elsif :ok != (verbability = current_account_can_verb_record?(action_name, record))
          verbability
        elsif !callback(:during_find, record, opts)
          # callbacks failed
          :unauthed
        else
          :ok
        end
        
        if :ok == result
          assign_resource record
        else
          escort result
        end
      end
      
      def retrieve_record opts = {}
        finder = opts[:finder] || :find_by_id
        val = opts[:id] || params[:id]

        record = mdl.send finder, val

        if record.nil?
          # not found
        elsif !opts[:deleted_ok] && record.deleted?
          log "#{record.class}<#{record.id}> has been deleted."
        else
          record
        end
      end
      
      def escort reason
        redirect_to({
          :read_only => {:action => :show}
        }[reason] || root_path)
      end
      
    end
  end
end
