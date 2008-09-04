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
        if !record.readable_by?(@current_account)
          log "#{@current_account.class}<#{@current_account.id}> can't see #{record.class}<#{record.id}>."
          :unauthed
        elsif !safe_action_and_implication?(verb) && !record.writeable_by?(@current_account)
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

      def verb_scope
        able = if 'index' == action_name
          'indexable'
        elsif safe_action_and_implication?
          'readable'
        else
          'writeable'
        end

        if @current_account && mdl.respond_to?("#{able}_by")
          mdl.send("#{able}_by", @current_account)
        else
          mdl.send able
        end
      end

      def retrieve_record opts = {}
        finder = opts[:column] || :id
        val = opts[finder] || params[finder]

        # record = mdl.send finder, val
        # TODO Hax Ambition so the eval isn't required to supply finder.
        # record = mdl.readable_by(@current_account).select {|r| r.__send__(finder) == val }.first
        record = eval "verb_scope.select {|r| r.#{finder} == val }.first"

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
          :read_only => {:action => :show},
          :unauthed => (@current_account ? root_path : login_path)
        }[reason] || root_path)
      end

    end
  end
end
