# This loads hammock when it's present as a plugin.
# As a gem, it's loaded from lib/hammock.rb.
ActionController::Base.send :include, Hammock
