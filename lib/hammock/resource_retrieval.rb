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
      
      # def empty_scope
      #   proc {|ticket| false }
      # end
      
      # def viewable_scope;   mdl.select &mdl.visible_to?(@current_account)   end
      # def editable_scope;   mdl.select &mdl.editable_by?(@current_account)   end
      # def indexable_scope;  mdl.select &mdl.indexable_by?(@current_account)  end
      # def createable_scope; mdl.select &mdl.createable_by?(@current_account) end
      
      # def correct_scope_type scope
      #   scope.is_a?(Ambition::Context)
      # end
      
      # def appropriate_scope
      #   if 'index' == action_name
      #     indexable_scope
      #   elsif idempotent_action_and_implication? action_name
      #     viewable_scope
      #   else
      #     editable_scope
      #   end
      # end
      
      # def resource_scope
      #   result = if action_requires_record? action_name
      #     report "Non-scopeable action #{table_name}/#{action_name}."
      #   elsif !correct_scope_type(scope = appropriate_scope)
      #   # elsif (scope = appropriate_scope).nil?
      #     log "No scope defined for #{mdl}."
      #     :not_found
      #   else
      #     :ok
      #   end
      #   
      #   if :ok == result
      #     @current_scope = scope
      #     # mdl.nestable_record_ids.inject(scope) {|scope,record_id|
      #     #   if params[record_id].blank?
      #     #     scope
      #     #   else
      #     #     scope.scope_to :conditions => mdl.nest_conditions_for(record_id, params[record_id])
      #     #   end
      #     # }
      #   else
      #     escort result
      #   end
      # end

      # def retrieve_records
      #   assign_resource resource_scope
      # end
      
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
          # @current_link = link
          assign_resource record
        else
          escort result
        end
      end
      
      def retrieve_record opts = {}
        # if !correct_scope_type(scope = appropriate_scope)
        # if (scope = appropriate_scope).nil?
          # log "No scope defined for #{mdl}##{action_name}."
        # else
          finder = opts[:finder] || :find_by_id
          val = opts[:id] || params[:id]

          record = mdl.send finder, val
          # record = scope.send finder, val
          # TODO: ambition improvements should allow us to remove this eval at some point
          # record = eval("scope.select {|r| r.#{finder_column} == val }").first

          if record.nil?
            # not found
          elsif !opts[:deleted_ok] && record.deleted?
            log "#{record.class}<#{record.id}> has been deleted."
          else
            record
          end
        # end
      end
      
      def escort reason
        redirect_to({
          :read_only => {:action => :show}
        }[reason] || root_path)
      end
      
    end
  end
end
