gem 'benhoskings-ambition'
gem 'benhoskings-ambitious-activerecord'
require 'ambition'
require 'ambition/adapters/active_record'

module Hammock
  VERSION = '0.2.11.4'

  def self.included base # :nodoc:
    Dir.glob("#{File.dirname __FILE__}/hammock/**/*.rb").each {|dep|
      require dep
    }

    Hammock.constants.map {|constant_name|
      Hammock.const_get constant_name
    }.select {|constant|
      constant.is_a?(Module) && !constant.is_a?(Class)
    }.partition {|mod|
      mod.constants.include?('LoadFirst') && mod::LoadFirst
    }.flatten.each {|mod|
      target = mod.constants.include?('MixInto') ? mod::MixInto : base
      target.send :include, mod
    }
  end

  def self.loaded_from_gem?
    File.dirname(__FILE__)[`gem env gemdir`.chomp]
  end
end

# This is done in init.rb when Hammock is loaded as a plugin.
ActionController::Base.send :include, Hammock if Hammock.loaded_from_gem?
