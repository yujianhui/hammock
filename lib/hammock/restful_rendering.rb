module Hammock
  module RestfulRendering
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods

      def do_render opts = {}
        if request.xhr?
          if params[:attribute]
            render_attribute opts
          elsif params[:display_as]
            render_as
          else
            render :partial => "#{table_name}/#{mdl_name}#{'_edit' if opts[:edit]}"
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
