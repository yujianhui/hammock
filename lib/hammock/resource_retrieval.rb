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

      def find_record finder = :find
        result = if !callback(:before_find)
          # callbacks failed
        elsif (record = retrieve_record(finder)).nil?
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
          if pagination_enabled?
            assign_entity scope.paginate(:page => params[:page])
          else
            assign_entity scope
          end
        end
      end

      def retrieve_record finder
        if (scope = current_scope).nil?

        else
          record = scope.send finder, :first, :conditions => {mdl.routing_attribute => params[:id]}
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
          # TODO Write a 403 partial.
          render_for_status 404
        elsif current_user.nil? && account_verb_scope?
          escort_for_login
        else
          render_for_status 404
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

      def render_for_status code
        log code
        if partial_exists? "#{controller_name}/status_#{code}"
          render :partial => "#{controller_name}/status_#{code}", :layout => true, :status => code
        elsif partial_exists? "shared/status_#{code}"
          render :partial => "shared/status_#{code}", :layout => true, :status => code
        else
          render :file => File.join(RAILS_ROOT, "public/#{code}.html"), :status => code
        end
      end

    end
  end
end
