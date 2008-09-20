module Hammock
  module ResourceRetrieval
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      base.class_eval {
        helper_method :can_verb_record?
      }
    end

    module ClassMethods
    end

    module InstanceMethods

      def can_verb_record? verb, record
        if !can_read_record?(record)
          log "#{requester_name} can't see #{record.class}<#{record.id}>."
          :not_found
        elsif !safe_action_and_implication?(verb) && !can_write_record?(record)
          log "#{requester_name} can't #{verb} #{record.class}<#{record.id}>."
          :read_only
        else
          log "#{requester_name} can #{verb} #{record.class}<#{record.id}>."
          :ok
        end
      end

      def find_record opts = {}
        result = if !callback(:before_find)
          # callbacks failed
        elsif (record = retrieve_record(opts)).nil?
          :not_found
        elsif :ok != (verbability = can_verb_record?(action_name, record))
          verbability
        elsif !callback(:during_find, record, opts)
          # callbacks failed
          :not_found
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
        if @current_account && (scope_name = account_verb_scope?)
          log "got an account_verb_scope #{scope_name}."
          mdl.send(scope_name, @current_account)
        elsif !(scope_name = public_verb_scope?)
          log "No #{@current_account.nil? ? 'public' : 'account'} #{verb_scope_name} scope available for #{mdl}.#{' May be available after login.' if account_verb_scope?}"
          nil
        else
          log "got a public_verb_scope #{scope_name}."
          mdl.send scope_name
        end
      end

      def nest_scope
        params.symbolize_keys.dragnet(*self.class.nestable_resources).inject(mdl.ambition_context) {|acc,(k,v)|
          # TODO this would be more ductile if it used AR assocs instead of explicit FK
          eval "acc.select {|r| r.#{k} == #{v.to_decl} }"
        }
      end
      
      def current_scope
        nest_scope.chain verb_scope
      end

      def retrieve_resource
        if (scope = current_scope).nil?
          escort :not_found
        else
          assign_resource scope
        end
      end

      def retrieve_record opts = {}
        finder = opts[:column] || :id
        val = opts[finder] || params[finder]

        if (scope = current_scope).nil?
          nil
        else
          # record = mdl.send finder, val
          # TODO Hax Ambition so the eval isn't required to supply finder.
          # record = mdl.readable_by(@current_account).select {|r| r.__send__(finder) == val }.first
          record = eval "scope.select {|r| r.#{finder} == val }.first"

          if record.nil?
            # not found
          elsif !opts[:deleted_ok] && record.deleted?
            log "#{record.class}<#{record.id}> has been deleted."
          else
            record
          end
        end
      end

      def escort reason
        if request.xhr?
          escort_for_bad_request
        elsif :readonly == reason
          escort_for_read_only
        elsif @current_account.nil? && account_verb_scope?
          escort_for_login
        else
          escort_for_404
        end
        nil
      end

      private

      def returning_login_path
        session[:path_after_login] = request.request_uri
        login_path
      end

      def verb_scope_name
        if 'index' == action_name
          'indexable'
        elsif safe_action_and_implication?
          'readable'
        else
          'writeable'
        end
      end
      
      def requester_name
        @current_account.nil? ? 'Anonymous' : "#{@current_account.class}<#{@current_account.id}>"
      end

      def can_read_record? record
        if @current_account.nil?
          record.readable?
        else
          record.readable_by? @current_account
        end
      end

      def can_write_record? record
        if @current_account.nil?
          record.writeable?
        else
          record.writeable_by? @current_account
        end
      end

      def account_verb_scope?
        able = "#{verb_scope_name}_by"
        able if mdl.respond_to?(able)
      end
      def public_verb_scope?
        able = verb_scope_name
        able if mdl.respond_to?(able)
      end
      def escort_for_bad_request
        log
        render :nothing => true, :status => 400
      end
      def escort_for_read_only
        log
        redirect_to :action => :show
      end
      def escort_for_login
        log
        # render :partial => 'login/account', :status => 401 # unauthorized
        redirect_to returning_login_path
      end
      def escort_for_404
        log
        render :file => File.join(RAILS_ROOT, 'public/404.html'), :status => 404 # not found
      end

    end
  end
end
