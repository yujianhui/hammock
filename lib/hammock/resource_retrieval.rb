module Hammock
  module ResourceRetrieval
    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods
      private

      def find_deleted_record
        find_record :find_with_deleted
      end

      def find_record
        result = if !callback(:before_find)
          # callbacks failed
        elsif (record = retrieve_record).nil?
          log "#{mdl}<#{params[:id]}> doesn't exist within #{requester_name.possessive} #{action_name} scope."
          :not_found
        elsif :ok != (verbability = can_verb_record?(action_name.to_sym, record))
          verbability
        elsif !callback(:during_find, record)
          # callbacks failed
        else
          :ok
        end

        if :ok != result
          escort(result)
        else
          assign_entity record
        end
      end

      def retrieve_resource
        if (scope = current_scope).nil?
          escort :unauthed
        else
          assign_entity scope
        end
      end

      def retrieve_record
        if (scope = current_scope).nil?

        else
          record = scope.send :find, :first, :conditions => {find_column_name => params[:id]}
          record || required_callback(:after_failed_find)
        end
      end

      def escort reason
        if rendered_or_redirected?
          # lol
        elsif request.xhr?
          # TODO bad request might only be appropriate for invalid requests, as opposed to just an auth failure.
          escort_for_bad_request
        elsif :relogin == reason
          reset_session # TODO: instead of a full reset, this should just set unauthed so we can remember who the user was without granting them their creds.
          redirect_to returning_login_path
        elsif :readonly == reason
          escort_for_read_only
        elsif :unauthed == reason
          escort_for_403
        elsif @current_account.nil? && account_verb_scope?
          escort_for_login
        else
          escort_for_404
        end
        false
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
        if partial_exists? 'shared/status_404'
          render :partial => 'shared/status_404', :layout => true
        else
          render :file => File.join(RAILS_ROOT, 'public/404.html'), :status => 404
        end
      end
      def escort_for_403
        if partial_exists? 'shared/status_404'
          render :partial => 'shared/status_404', :layout => true
        else
          render :file => File.join(RAILS_ROOT, 'public/404.html'), :status => 403
        end
      end

    end
  end
end
