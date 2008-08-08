Dir.glob("#{File.dirname __FILE__}/hammock/*.rb").each {|dep|
  require "hammock/#{File.basename(dep)}"
}

module Hammock
  def self.included base
    # Callbacks have to be loaded first since some modules register callbacks of their own.
    Hammock.constants.unshift('Callbacks').uniq.map {|const|
      Hammock.const_get const
    }.each {|const|
      mix_target = const.constants.include?('MixInto') ? const::MixInto : base
      mix_target.send(:include, const) if const.is_a? Module
      # puts "Mixed #{const} into #{mix_target}"
    }
  end
end
