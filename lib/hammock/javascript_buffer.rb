module Hammock
  module JavascriptBuffer
    MixInto = ActionView::Base
    
    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods

      # Add +snippet+ to the request's domready javascript cache.
      #
      # The contents of this cache can be rendered into a jQuery <tt>$(function() { ... })</tt> block within a <tt>\<script type="text/javascript"></tt> block by calling <tt>javascript_for_page</tt> within the \<head> of the layout.
      def append_javascript snippet
        # TODO This should be an array of strings.
        @_domready_javascript ||= ''
        @_domready_javascript << snippet.strip.end_with(';') << "\n\n" unless snippet.nil?
      end

      # Add +snippet+ to the request's toplevel javascript cache.
      #
      # The contents of this cache can be rendered into a <tt>\<script type="text/javascript"></tt> block by calling <tt>javascript_for_page</tt> within the \<head> of the layout.
      def append_toplevel_javascript snippet
        @_toplevel_javascript ||= ''
        @_toplevel_javascript << snippet.strip.end_with(';') << "\n\n" unless snippet.nil?
      end

      # Render the snippets cached by +append_javascript+ and +append_toplevel_javascript+ within a <tt>\<script type="text/javascript"></tt> tag.
      #
      # This should be called somewhere within the \<head> in your layout.
      def javascript_for_page
        javascript_tag %Q{
          #{@_toplevel_javascript}

          (jQuery)(function() {
            #{@_domready_javascript}
          });
        }
      end

      # If the current request is XHR, render all cached javascript as +javascript_for_page+ would and clear the request's javascript cache.
      #
      # The purpose of this method is for rendering javascript into partials that form XHR responses, without causing duplicate javascript to be rendered by nested partials multiply calling this method.
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
