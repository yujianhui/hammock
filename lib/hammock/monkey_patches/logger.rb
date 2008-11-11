module Hammock
  module BufferedLoggerPatches
    MixInto = ActiveSupport::BufferedLogger

    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      # base.class_eval {
      #   alias_method_chain :fatal, :color
      # }
    end

    module ClassMethods

    end

    module InstanceMethods

      def fatal_with_color message = nil, progname = nil, &block
        first_line, other_lines = message.strip.split("\n", 2)
        fatal_without_color "\n" + first_line.colorize('on red'), progname, &block
        fatal_without_color other_lines.colorize('red') + "\n\n", progname, &block
      end

    end
  end
end
