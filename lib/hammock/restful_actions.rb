module Hammock
  module RestfulActions
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods

      # TODO implement filtering of records based on named routes, e.g. transfers to a single account:
      # /accounts/481/transfers (check)
      def index
        assign_named_record_instances index_finder
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
          result = callback(:before_destroy) and @record.delete and callback(:after_destroy)
          render_for_delete result
        end
      end

      def undestroy
        if find_record(:deleted_ok => true) {|record| @current_account.can_undestroy? record }
          result = callback(:before_undestroy) and @record.undelete and callback(:after_undestroy)
          render_for_delete result, :undelete => true
        end
      end

      def render_or_redirect_after result
        if request.xhr?
          do_render :editable => true, :edit => false
        else
          if result
            redirect_to postsave_redirect || path_for(mdl)
          else
            referring_action = inline_edit ? :index : (@record.new_record? ? :new : :edit)
            send referring_action
            render :template => "restful/#{referring_action}"
          end
        end
      end

      def render_for_delete success, opts = {}
        if request.xhr?
          render :partial => "#{table_name}/index_entry", :locals => { :record => @record }
        else
          if success
            if opts[:undelete]
              flash[:info] = "#{@record.display_name} was undeleted."
              redirect_back_or opts[:redirect_path] || record_path(@record)
            else
              flash[:info] = "#{@record.display_name} was deleted &mdash; #{render_to_string :partial => 'restful/undelete_link'}"
              flash[:blind] = true
              redirect_to opts[:redirect_path] || records_path(@record.class)
            end
          else
            flash[:error] = "#{opts[:undelete] ? 'Und' : 'D'}elete failed."
            redirect_to opts[:redirect_path] || records_path(@record.class)
          end
        end
      end

    end
  end
end
