module Hammock
  module JavascriptBuffer
    MixInto = ActionView::Base
    
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods

      def append_javascript snippet
        @_domready_javascript ||= ''
        @_domready_javascript << snippet.strip.end_with(';') << "\n\n"
      end

      def append_toplevel_javascript snippet
        @_toplevel_javascript ||= ''
        @_toplevel_javascript << snippet.strip.end_with(';') << "\n\n"
      end

      def javascript_for_page
        javascript_tag %Q{
          #{@_toplevel_javascript}

          (jQuery)(function() {
            #{@_domready_javascript}
          });
        }
      end

      def javascript_for_ajax_response
        # TODO this should be called from outside the partials somewhere, once only
        if request.xhr?
          js = javascript_for_page
          clear_js_caches
          js
        end
      end

      def clear_js_caches
        @_domready_javascript = @_toplevel_javascript = nil
      end

    end
  end
end
