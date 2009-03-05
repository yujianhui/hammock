module Hammock
  module HashPatches
    MixInto = Hash
    
    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods

      def discard! *keys
        keys.each {|k| delete k }
        self
      end

      def discard *keys
        dup.discard! *keys
      end

      def selekt &block
        hsh = {}
        each_pair {|k,v|
          hsh[k] = v if yield(k,v)
        }
        hsh
      end

      def dragnet *keys
        dup.dragnet! *keys
      end

      def dragnet! *keys
        keys.inject({}) {|acc,key|
          acc[key] = self.delete(key) if self.has_key?(key)
          acc
        }
      end

      def to_param_hash prefix = ''
        hsh = self.dup
        # TODO these two blocks can probably be combined
        hsh.keys.each {|k| hsh.merge!(hsh.delete(k).to_param_hash(k)) if hsh[k].is_a?(Hash) }
        hsh.keys.each {|k| hsh["#{prefix}[#{k}]"] = hsh.delete(k) } unless prefix.blank?
        hsh
      end

      def to_flattened_json
        to_param_hash.to_json
      end

    end
  end
end
