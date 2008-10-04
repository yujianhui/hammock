module Hammock
  module LinkTo
    MixInto = ActionView::Base
    
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods
      def link_to_if_allowed verb, record, opts = {}
        if :ok == can_verb_record?(verb, record)
          link_to opts[:text] || verb.to_s.capitalize, path_for(verb, record, opts), :method => method_for(verb, record)
        end
      end
    end
  end
end
