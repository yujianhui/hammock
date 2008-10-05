module Hammock
  module ResourceRetrieval
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods

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

      def retrieve_resource
        if (scope = current_scope).nil?
          escort :not_found
        else
          assign_resource scope
        end
      end

      def retrieve_record opts = {}
        val = params[:id]

        if (scope = current_scope).nil?
          nil
        else
          # record = mdl.send finder, val
          # TODO Hax Ambition so the eval isn't required to supply finder.
          # record = mdl.readable_by(@current_account).select {|r| r.__send__(finder) == val }.first
          record = eval "scope.select {|r| r.#{self.class.find_column_name} == val }.first"

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
