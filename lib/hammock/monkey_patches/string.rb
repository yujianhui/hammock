module Hammock
  module StringPatches
    MixInto = String
    
    def self.included base # :nodoc:
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods

      # Generates a random string consisting of +length+ hexadecimal characters (i.e. matching [0-9a-f]{length}).
      def af09 length = 1
        (1..length).inject('') {|a, t|
          a << rand(16).to_s(16)
        }
      end

      # Generates a random string consisting of +length+ alphamuneric characters (i.e. matching [0-9a-zA-Z]{length}).
      def azAZ09 length = 1
        (1..length).inject('') {|a, t|
          a << ((r = rand(62)) < 36 ? r.to_s(36) : (r - 26).to_s(36).upcase)
        }
      end

    end

    module InstanceMethods

      # Returns true iff +str+ appears exactly at the start of +self+.
      def starts_with? str
        self[0, str.length] == str
      end

      # Returns true iff +str+ appears exactly at the end of +self+.
      def ends_with? str
        self[-str.length, str.length] == str
      end

      # Return a duplicate of +self+, with +str+ prepended to it if it doesn't already start with +str+.
      def start_with str
        starts_with?(str) ? self : str + self
      end

      # Return a duplicate of +self+, with +str+ appended to it if it doesn't already end with +str+.
      def end_with str
        ends_with?(str) ? self : self + str
      end

    end
  end
end