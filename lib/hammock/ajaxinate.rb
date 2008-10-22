module Hammock
  module Ajaxinate
    MixInto = ActionView::Base
    
    def self.included base
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
        if :ok == can_verb_entity?(verb, record)
          link_path = ajaxinate verb, record, opts

          content_tag :a,
            opts[:text] || verb.to_s.capitalize,
            :id => link_id_for(verb, record),
            :class => opts[:class],
            :href => link_path,
            :onclick => 'return false;',
            :style => opts[:style]
        end
      end

      def ajaxinate verb, record, opts = {}
        record_attributes = {record.base_model => record.unsaved_attributes}
        link_params = {record.base_model => (opts.delete(:record) || {}) }.merge(opts[:params] || {})
        request_method = method_for verb, record
        link_path = path_for verb, record
        attribute = link_params[:attribute]
        link_id = link_id_for verb, record, attribute

        request_method, link_params[:_method] = :post, request_method unless [:get, :post].include?(request_method)

        form_elements_hash = if :get == request_method
          '{ }'
        elsif attribute.blank?
          "(jQuery)('form').serializeHash()"
        else
          "{ '#{record.base_model}[#{attribute}]': $('##{link_id}').val() }"
        end

        # TODO check the response code in the callback, and replace :after with :success and :failure.
        js = %Q{
          (jQuery)('##{link_id}').#{opts[:on] || 'click'}(function() {
            if (#{attribute.blank? ? 'false' : 'true'} && (jQuery('##{link_id}_target .original_value').html() == jQuery('##{link_id}_target .modify input').val())) {
              eval("#{clean_snippet opts[:skipped]}");
            } else if (!eval("#{clean_snippet opts[:before]}")) { // before callback failed
              
            } else { // fire the request
              jQuery.#{request_method}(
                '#{link_path}',
                jQuery.extend(
                  #{record_attributes.to_flattened_json},
                  #{form_elements_hash},
                  #{link_params.to_flattened_json},
                  #{forgery_key_json(request_method)}
                ),
                function(response) {
                  //log("response: " + response);
                  //(jQuery)('.#{opts[:target] || link_id + '_target'}').html(response);
                  (jQuery)('##{opts[:target] || link_id + '_target'}').before(response).remove();
                  eval("#{clean_snippet opts[:after]}");
                }
              );
            }
          });
        }

        append_javascript js
        link_path
      end

      private

      def link_id_for verb, record, attribute = nil
        [verb, record.base_model, record.id_or_describer.gsub(/[^a-zA-Z0-9-_]/, ''), attribute].compact.join('_')
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
