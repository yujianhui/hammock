# TODO Oh dear lord these probably shouldn't be here. But that's OK for now. Because it's a spike!
# Yes, a spike. Nothing to see here.

class Object

  def symbolize
    self.to_s.underscore.to_sym
  end

end

class Hash

  def dragnet *keys
    keys.inject({}) {|acc,key|
      acc[key] = self[key] if self.has_key?(key)
      acc
    }
  end

end
