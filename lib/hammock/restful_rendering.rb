module Hammock
  module RestfulRendering
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods

      private

      def standard_render
        respond_to do |format|
          format.html
          format.xml { render :xml => @record }
        end
      end

      def do_render result = true, opts = {}
        if request.xhr?
          if params[:attribute]
            render_attribute opts
          elsif params[:display_as]
            render_as
          else
            render :nothing => true, :status => (result ? 200 : 500)
          end
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

    end
  end
end
