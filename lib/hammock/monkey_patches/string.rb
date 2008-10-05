module Hammock
  module StringPatches
    MixInto = String
    
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods

      # Generates a random string consisting of hexadecimal characters (i.e. [0-9a-f]).
      def af09(length = 1)
        (1..length).inject('') {|a, t| a << rand(16).to_s(16) }
      end

      # Generates a random string consisting of characters from [0-9a-zA-Z].
      def azAZ09(length = 1)
        (1..length).inject('') {|a, t| a << ((r = rand(62)) < 36 ? r.to_s(36) : (r - 26).to_s(36).upcase) }
      end

    end

    module InstanceMethods

      def starts_with?(str)
        self[0, str.length] == str
      end

      def ends_with?(str)
        self[-str.length, str.length] == str
      end

      def start_with(str)
        starts_with?(str) ? self : str + self
      end

      def end_with(str)
        ends_with?(str) ? self : self + str
      end

    end
  end
end