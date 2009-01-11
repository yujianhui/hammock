module Hammock
  module RestfulRendering
    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods

      private

      def render_or_redirect_after result
        if request.xhr?
          render_for_safe_actions result, :editable => true, :edit => false
        else
          if postsave_render result
            # rendered - no redirect
          elsif result
            render_http_success
          else
            render_http_failure
          end
        end
      end

      def render_for_safe_actions result = true, opts = {}
        if request.xhr?
          if params[:attribute]
            render_attribute opts
          elsif params[:display_as]
            render_as
          else
            respond_to {|format|
              format.html { render :nothing => true, :status => (result ? 200 : 500) }
              format.xml
              format.js
            }
          end
        else
          respond_to do |format|
            format.html
            format.xml { render :xml => @record }
            format.js
          end unless rendered_or_redirected?
        end
      end

      def render_http_success
        flash[:notice] = "#{mdl} was successfully #{@record.new_or_deleted_before_save? ? 'created' : 'updated'}."
        respond_to do |format|
          format.html { redirect_back_or(postsave_redirect || nested_path_for((@record unless inline_createable_resource?) || mdl)) }
          format.xml {
            if @record.new_or_deleted_before_save?
              render :xml => @record, :status => :created, :location => @record
            else # update
              head :ok
            end
          }
          format.js
          format.json { render :json => {:result => 'success'}.to_json }
        end
      end
      
      def render_http_failure
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
          format.js
          format.json { render :json => {:result => 'failure'}.to_json }
        end
      end

      def render_attribute opts = {}
        render :partial => "restful/attribute", :locals => {
          :record => @record,
          :attribute => params[:attribute],
          :editable => opts[:editable],
          :editing => editing?(@record)
        }
      end

      def render_for_destroy success, opts = {}
        if request.xhr?
          render :partial => "shared/destroy", :locals => { :record => @record }
        else
          respond_to do |format|
            format.html { redirect_to postdestroy_redirect || nested_path_for(@record.class) }
            format.xml  { head :ok }
            format.js { render :partial => 'shared/destroy', :locals => {:record => @record} }
          end
        end
      end

    end
  end
end
