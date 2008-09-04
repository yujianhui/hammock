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
        assign_resource verb_scope
        @title = mdl.to_s.pluralize

        callback :before_index
        send(:new) if inline_edit
      end

      def new
        make_new_record
        do_render(:edit => true) if callback(:before_modify) and callback(:before_new)
      end

      def create
        make_new_record
        render_or_redirect_after save_record
      end

      def show
        if find_record
          do_render if callback(:before_show)
        end
      end

      def edit
        if find_record
          do_render(:edit => true) if callback(:before_modify) and callback(:before_edit)
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
          render_for_delete result
        end
      end

      def suggest
        @results = []

        if params[:keys].blank? || (@keys = params[:keys].split(',')).empty?
          log "No keys specified."
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

            :order => @keys.map {|k| "#{k} ASC" }.join(", "),
            :limit => 15
          ).sort_by {|record| record.suggestion_matches }.reverse
        end

        render :action => "suggest_#{@keys.join(',')}", :layout => false
      end


      private

      def render_or_redirect_after result
        if request.xhr?
          do_render :editable => true, :edit => false
        else
          if postsave_render result
            # rendered - no redirect
          elsif result
             redirect_to postsave_redirect || path_for(@record || mdl)
          else
            referring_action = inline_edit ? :index : (@record.new_record? ? :new : :edit)
            render :template => "#{table_name}/#{referring_action}"
          end
        end
      end

      def render_for_delete success, opts = {}
        if request.xhr?
          render :partial => "#{table_name}/index_entry", :locals => { :record => @record }
        else
          redirect_to opts[:redirect_path] || postdestroy_redirect || path_for(@record.class)
        end
      end

    end
  end
end
