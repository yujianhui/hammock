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
        if retrieve_resource
          callback :before_index
          tasks_for_new if inline_edit

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
        make_new_record
        render_or_redirect_after save_record
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

      def save_record
        verb = @record.new_record? ? 'create' : 'update'
        callback("before_#{verb}") and callback(:before_save) and
        @record.save and
        callback("after_#{verb}") and callback(:after_save)
      end

      def destroy
        if find_record(:deleted_ok => true) {|record| @current_account.can_destroy? record }
          result = callback(:before_destroy) and @record.destroy and callback(:after_destroy)
          render_for_destroy result
        end
      end

      def undestroy
        if find_record(:deleted_ok => true) {|record| @current_account.can_destroy? record }
          result = callback(:before_undestroy) and @record.undestroy and callback(:after_undestroy)
          render_for_destroy result
        end
      end

      def suggest
        @results = []

        if params[:keys].blank? || (@keys = params[:keys].split(',')).empty?
          log "No keys specified."
        elsif !callback(:before_suggest)
          # fail
        else
          @queries = (params[:q] || '').downcase.split(/\s+/)

          # She may not look like much, but she's got it where it counts, kid

          table_name = mdl.to_s.downcase.pluralize

          match_counter_sql_array = [
            @keys.map {|k| ([ "CASE WHEN LOWER(#{table_name}.#{k.sanitise_column_name}) LIKE ? THEN 1 ELSE 0 END" ] * @queries.length).join(' + ') }.join(' + '),
          ].concat(@queries.map{|q| "%#{q}%" } * @keys.length)

          match_counter_sql = mdl.send :sanitize_sql_array, match_counter_sql_array

          @results = mdl.base_class.find(:all,
            :select => "*, #{match_counter_sql} AS suggestion_matches",
            :conditions => [
              @keys.map {|k| ([ "LOWER(#{table_name}.#{k.sanitise_column_name}) LIKE ?" ] * @queries.length).join(' OR ') }.join(' OR '),
            ].concat(@queries.map{|q| "%#{q}%" } * @keys.length),

            # TODO SQL injection
            :order => @keys.map {|k| "#{k} ASC" }.join(", "),
            :limit => 15
          ).sort_by {|record| record.suggestion_matches }.reverse
        end

        render :action => "suggest_#{@keys.join(',')}", :layout => false
      end


      private

      def tasks_for_new
        make_new_record and callback(:before_modify) and callback(:before_new)
      end

      def render_or_redirect_after result
        if request.xhr?
          do_render :editable => true, :edit => false
        else
          if postsave_render result
            # rendered - no redirect
          else
            respond_to do |format|
              if result
                flash[:notice] = "Page was successfully #{'create' == action_name ? 'created' : 'updated'}."
                format.html { redirect_to(postsave_redirect || path_for(@record || mdl)) }
                format.xml {
                  if 'create' == action_name
                    render :xml => @record, :status => :created, :location => @record
                  else # update
                    head :ok
                  end
                }
              else
                format.html {
                  if inline_edit
                    index
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
          render :partial => "#{table_name}/index_entry", :locals => { :record => @record }
        else
          flash[:error] = "#{@record.name} was removed."
          respond_to do |format|
            format.html { redirect_to(opts[:redirect_path] || postdestroy_redirect || path_for(@record.class)) }
            format.xml  { head :ok }
          end
        end
      end

    end
  end
end
