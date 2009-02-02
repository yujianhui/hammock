module Hammock
  module RoutePatches
    MixInto = ActionController::Routing::Route

    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods

      # TODO memoize these
      def verb
        requirements[:action].to_sym
      end
      def resource
        Object.const_get requirements[:controller].classify
      end

      def nesting_matches? *records
        nestable_segments.all? {|segment|
          records.shift.is_a? segment.resource
        }
      end
      
      def format_matches? format
        has_format = segments.detect {|segment|
          segment.respond_to?(:key) && segment.key == :format
        }
        
        has_format.nil? ^ format
      end
      

      def render *records
        opts = records.extract_options!
        
        records << opts[:format] unless opts[:format].nil?
        
        unless records.length == renderable_segments.length
          raise ArgumentError, "#{renderable_segments.length} records are required to render this route, but #{records.length} were supplied."
        end

        segments.map {|segment|
          if segment.respond_to? :render
            segment.render records.shift
          else
            segment
          end.to_s
        }.join
      end

      private

      def renderable_segments
        segments.select {|segment| segment.respond_to? :render }.delete_if {|segment| segment.key == :format }
      end
      def nestable_segments
        renderable_segments.delete_if {|segment| segment.key == :id }
      end

    end
  end
end

