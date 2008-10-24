module Hammock
  module RestfulActions
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods

      def index
        if tasks_for_index
          respond_to do |format|
            format.html # index.html.erb
            format.xml { render :xml => @records.kick }
          end
        end
      end

      def new
        do_render || standard_render if tasks_for_new
      end

      def create
        render_or_redirect_after(find_record_on_create || (make_createable_record && save_record)) if createable?
      end

      def show
        if find_record
          do_render || standard_render if callback(:before_show)
        end
      end

      def edit
        if find_record
          do_render if callback(:before_modify) and callback(:before_edit)
        end
      end

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

      def destroy
        if find_record
          result = callback(:before_destroy) and @record.destroy and callback(:after_destroy)
          render_for_destroy result
        end
      end

      # def undestroy
      #   if find_deleted_record
      #     result = callback(:before_undestroy) and @record.undestroy and callback(:after_undestroy)
      #     render_for_destroy result
      #   end
      # end

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
        make_new_record and callback(:before_modify) and callback(:before_new) if createable?
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

      def render_or_redirect_after result
        if request.xhr?
          do_render result, :editable => true, :edit => false
        else
          if postsave_render result
            # rendered - no redirect
          else
            if result
              flash[:notice] = "#{mdl} was successfully #{'create' == action_name ? 'created' : 'updated'}."
              respond_to do |format|
                format.html { redirect_to postsave_redirect || nested_path_for((@record unless inline_createable_resource?) || mdl) }
                format.xml {
                  if 'create' == action_name
                    render :xml => @record, :status => :created, :location => @record
                  else # update
                    head :ok
                  end
                }
              end
            else
              respond_to do |format|
                format.html {
                  if inline_createable_resource?
                    tasks_for_index
                    render :action => :index
                  else
                    render :action => (@record.new_record? ? 'new' : 'edit')
                  end
                }
                format.xml { render :xml => @record.errors, :status => :unprocessable_entity }
              end
            end
          end
        end
      end

      def render_for_destroy success, opts = {}
        if request.xhr?
          render :partial => "#{mdl.table_name}/index_entry", :locals => { :record => @record }
        else
          respond_to do |format|
            format.html { redirect_to postdestroy_redirect || nested_path_for(@record.class) }
            format.xml  { head :ok }
          end
        end
      end

    end
  end
end
