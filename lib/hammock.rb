Dir.glob("#{File.dirname __FILE__}/hammock/*.rb").each {|dep|
  require "hammock/#{File.basename(dep)}"
}

module Hammock
  def self.included base
    # Callbacks have to be loaded first since some modules register callbacks of their own.
    Hammock.constants.unshift('Callbacks').uniq.map {|const|
      Hammock.const_get const
    }.each {|const|
      base.send(:include, const) if const.is_a? Module
    }
  end
end
