gem 'benhoskings-ambition'
gem 'benhoskings-ambitious-activerecord'
require 'ambition'
require 'ambition/adapters/active_record'

Dir.glob("#{File.dirname __FILE__}/hammock/**/*.rb").each {|dep|
  require dep
} if defined?(RAILS_ROOT) # Loading Hammock components under 'rake package' fails.

module Hammock
  VERSION = '0.2.11.2'

  def self.included base # :nodoc:
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
end

class ApplicationController < ActionController::Base
  include Hammock
end
