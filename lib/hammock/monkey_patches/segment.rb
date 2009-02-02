module Hammock
  module SegmentPatches
    MixInto = ActionController::Routing::DynamicSegment

    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods

      # TODO memoize this
      def resource
        key_string = key.to_s
        Object.const_get key_string.chomp('_id').classify if key_string.ends_with?('_id')
      end

      def render record
        if key == :format
          record
        elsif key == :id
          record.to_param
        else
          raise "Route segment #{key} couldn't be filled by #{record.inspect}." unless record.is_a?(resource)
          record.to_param
        end
      end

    end
  end
end

