module Hammock
  module RestfulActions
    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods

      # The +index+ action. (GET, safe, idempotent)
      #
      # Lists the current resource's records that are visible within the current index scope, defined by +index_scope+ and +index_scope_for+ on the current model.
      def index
        if tasks_for_index
          respond_to do |format|
            format.html
            format.xml { render :xml => @records.kick }
            format.json { render :json => @records.kick }
            format.yaml { render :text => @records.kick.to_yaml }
          end
        end
      end

      # The +new+ action. (GET, safe, idempotent)
      #
      # Renders a form containing the required fields to create a new record.
      #
      # This action is available within the same scope as +create+, since it is only useful if a subsequent +create+ would be successful.
      def new
        if !tasks_for_new
          escort :unauthed
        else
          render_for_safe_actions
        end
      end

      # The +create+ action. (POST, unsafe, non-idempotent)
      #
      # Creates a new record with the supplied attributes. TODO
      def create
        if !find_record_on_create && !make_createable?
          escort :unauthed
        else
          render_or_redirect_after save_record
        end
      end

      # The +show+ action. (GET, safe, idempotent)
      #
      # Displays the specified record if it is within the current read scope, defined by +read_scope+ and +read_scope_for+ on the current model.
      def show
        if find_record
          render_for_safe_actions if callback(:before_show)
        end
      end

      # The +edit+ action. (GET, safe, idempotent)
      #
      # Renders a form containing the fields populated with the current record's attributes.
      #
      # This action is available within the same scope as +update+, since it is only useful if a subsequent +update+ would be successful.
      def edit
        if find_record
          render_for_safe_actions if callback(:before_modify) and callback(:before_edit)
        end
      end

      # The +update+ action. (PUT, unsafe, idempotent)
      #
      # Updates the specified record with the supplied attributes if it is within the current write scope, defined by +write_scope+ and +write_scope_for+ on the current model.
      def update
        if find_record
          # If params[:attribute] is given, update only that attribute. We mass-assign either way to filter through attr_accessible.
          @record.attributes = if (attribute_name = params[:attribute])
            { attribute_name => params_for(mdl.symbolize)[attribute_name] }
          else
            params_for mdl.symbolize
          end

          render_or_redirect_after save_record
        end
      end

      # The +destroy+ action. (DELETE, unsafe, non-idempotent)
      #
      # Destroys the specified record if it is within the current write scope, defined by +write_scope+ and +write_scope_for+ on the current model.
      def destroy
        if find_record
          result = callback(:before_destroy) and @record.destroy and callback(:after_destroy)
          render_for_destroy result
        end
      end

      # The +undestroy+ action. (POST, unsafe, idempotent)
      #
      # Reverses a previous destroy on the specified record if it is within the current write scope, defined by +write_scope+ and +write_scope_for+ on the current model.
      def undestroy
        if find_deleted_record
          result = callback(:before_undestroy) and @record.undestroy and callback(:after_undestroy)
          render_for_destroy result
        end
      end

      # The +suggest+ action. (GET, safe, idempotent)
      #
      # Lists the current resource's records that would be listed by an index, filtered to show only those where at least one of the specified keys matches each whitespace-separated term in the query.
      def suggest
        @results = if params[:q].blank?
          log 'No query specified.'
        elsif params[:fields].blank?
          log "No fields specified."
        elsif !callback(:before_suggest)
          # fail
        else
          fields = params[:fields].split(',')
          @queries = params[:q].downcase.split(/\s+/)

          mdl.suggest fields, @queries
        end
        
        if @results.nil?
          escort_for_bad_request
        else
          callback(:after_suggest)
          render :action => "suggest_#{fields.join(',')}", :layout => false
        end
      end


      private

      def tasks_for_index
        retrieve_resource and callback(:before_index) and (!inline_createable_resource? || tasks_for_new)
      end

      def tasks_for_new
        callback(:before_modify) and callback(:before_new) if make_createable?
      end

      def find_record_on_create
        if findable_on_create?
          if record = nest_scope.find(:first, :conditions => params_for(mdl.symbolize))
            log "suitable record already exists: #{record}"
            assign_resource record
          else
            log "couldn't find a suitable record, proceeding with creation."
          end
        end
      end

      def save_record
        verb = @record.new_record? ? 'create' : 'update'
        if callback("before_#{verb}") and callback(:before_save) and save
          callback("after_#{verb}") and callback(:after_save)
        else
          log "#{mdl} errors: " + @record.errors.full_messages.join(', ')
          callback("after_failed_#{verb}") and callback(:after_failed_save) and false
        end
      end

      def save
        @record.save
      end

    end
  end
end
