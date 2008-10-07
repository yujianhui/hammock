Dir.glob("#{File.dirname __FILE__}/hammock/**/*.rb").each {|dep|
  require dep
}

module Hammock
  def self.included base
    Hammock.constants.map {|constant_name|
      Hammock.const_get constant_name
    }.select {|constant|
      constant.is_a? Module
    }.partition {|mod|
      mod.constants.include? 'LoadFirst'
    }.flatten.each {|mod|
      target = mod.constants.include?('MixInto') ? mod::MixInto : base
      target.send :include, mod
    }
  end
end
