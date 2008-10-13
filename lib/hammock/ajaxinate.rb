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
          link_id = opts[:link_id] || "#{verb}_#{record.base_model}_#{record.id}"
          link_path = ajaxinate link_id, verb, record, opts

          content_tag :a,
            opts[:text] || verb.to_s.capitalize,
            :id => link_id,
            :class => opts[:class],
            :href => link_path,
            :onclick => 'return false;',
            :style => opts[:style]
        end
      end

      def ajaxinate elem_id, verb, record, opts = {}
        link_params = { record.base_model => record.unsaved_attributes.merge(opts.delete(:record) || {}) }.merge(opts[:params] || {})
        link_id = opts[:link_id] || elem_id
        request_method = method_for verb, record
        link_path = path_for verb, record
        attribute = link_params[record.base_model][:attribute]

        request_method, link_params[:_method] = :post, request_method unless [ :get, :post ].include?(request_method)

        form_elements_hash = if :get == request_method
          '{ }'
        elsif attribute.blank?
          "(jQuery)('form').serializeHash()"
        else
          "{ '#{record.base_model}[#{attribute}]': $('##{link_id}').val() }"
        end

        js = %Q{
          (jQuery)('##{link_id}').#{opts[:on] || 'click'}(function() {
            jQuery.#{request_method}(
              '#{link_path}',
              jQuery.extend(
                jQuery.extend(
                  #{form_elements_hash},
                  #{link_params.to_flattened_json}
                ),
                #{forgery_key_json(request_method)}
              ),
              function(response) {
                //(jQuery)('.#{opts[:target] || link_id + '_target'}').html(response);
                (jQuery)('##{opts[:target] || link_id + '_target'}').before(response).remove();
              }
            );
          });
        }

        append_javascript js
        link_path
      end

      private

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
