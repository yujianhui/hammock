module Hammock
  module Ajaxinate
    MixInto = ActionView::Base
    
    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods

      def ajax_button verb, record, opts = {}
        ajax_link verb, record, opts.merge(:class => [opts[:class], 'button'].squash.join(' '))
      end

      def ajax_link verb, record, opts = {}
        if can_verb_entity?(verb, record)
          route = ajaxinate verb, record, opts

          content_tag :a,
            opts[:text] || route.verb.to_s.capitalize,
            :class => [opts[:class], link_class_for(route.verb, record)].squash.join(' '),
            :href => route.path,
            :onclick => 'return false;',
            :style => opts[:style]
        end
      end

      def ajaxinate verb, record, opts = {}
        record_attributes = {record.base_model => record.unsaved_attributes}
        link_params = {record.base_model => (opts.delete(:record) || {}) }.merge(opts[:params] || {})
        route = route_for verb, record
        attribute = link_params[:attribute]
        link_class = link_class_for route.verb, record, attribute

        link_params[:_method] = route.http_method
        link_params[:format] = opts[:format].to_s

        form_elements_hash = if route.get?
          '{ }'
        elsif attribute.blank?
          "jQuery('form').serializeHash()"
        else
          "{ '#{record.base_model}[#{attribute}]': $('.#{link_class}').val() }"
        end

        response_action = case link_params[:format].to_s
        when 'js'
          "eval(response)"
        else
          "jQuery('.#{opts[:target] || link_class + '_target'}').before(response).remove()"
        end

        # TODO check the response code in the callback, and replace :after with :success and :failure.
        js = %Q{
          jQuery('.#{link_class}').#{opts[:on] || 'click'}(function() {
            /*if (#{attribute.blank? ? 'false' : 'true'} && (jQuery('.#{link_class}_target .original_value').html() == jQuery('.#{link_class}_target .modify input').val())) {
              eval("#{clean_snippet opts[:skipped]}");
            } else*/ if (false == eval("#{clean_snippet opts[:before]}")) {
              // before callback failed
            } else { // fire the request
              jQuery.#{route.fake_http_method}(
                '#{route.path}',
                jQuery.extend(
                  #{record_attributes.to_flattened_json},
                  #{form_elements_hash},
                  #{link_params.to_flattened_json},
                  #{forgery_key_json(route.http_method)}
                ),
                function(response) {
                  #{response_action};
                  eval("#{clean_snippet opts[:after]}");
                }
              );
            }
          });
        }

        append_javascript js
        route
      end
      
      def status_callback
        %Q{
          if ('success' == textStatus) {
            jQuery('.success', jQuery('#' + jQuery(data).attr("id"))).show().fadeOut(4000);
          } else {
            jQuery('.statuses .failure', obj).hide();
            jQuery('.statuses .failure', obj).show().parents('obj').BlindUp();
          }
        }
      end

      def jquery_xhr verb, record, opts = {}
        route = route_for verb, record
        params = if opts[:params].is_a?(String)
          opts[:params].chomp(',').start_with('{').end_with('}')
        else
          (opts[:params] || {}).merge(record.base_model => (opts[:record] || {})).to_flattened_json
        end

        response_action = case opts[:format].to_s
        when 'js'
          "eval(data);"
        else
          "obj.replaceWith(data);"
        end

        %Q{
          if (typeof(obj) != 'undefined') {
            jQuery('.spinner', obj).show();
          }

          jQuery.#{route.fake_http_method}(
            '#{route.path}',
            jQuery.extend(
              #{params},
              {format: '#{opts[:format] || 'html'}', _method: '#{route.http_method}'},
              #{forgery_key_json(route.http_method)}
            ),
            function(data, textStatus) {
              #{response_action}
              #{status_callback}
              #{(opts[:callback] || '').end_with(';')}
            }
          );
        }
      end

      private

      def link_class_for verb, record, attribute = nil
        [verb, record.description, attribute].compact.join('_')
      end

      def clean_snippet snippet
        report "Double quote detected in snippet '#{snippet}'" if snippet['"'] unless snippet.nil?
        (snippet || '').gsub("\n", '\n').end_with(';')
      end

      def forgery_key_json request_method = nil
        if !protect_against_forgery? || (:get == (request_method || request.method))
          '{ }'
        else
          "{ '#{request_forgery_protection_token}': encodeURIComponent('#{escape_javascript(form_authenticity_token)}') }"
        end
      end

    end
  end
end
