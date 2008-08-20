# TODO Oh dear lord these probably shouldn't be here. But that's OK for now. Because it's a spike!
# Yes, a spike. Nothing to see here.

class Object

  def symbolize
    self.to_s.underscore.to_sym
  end

end

# No, no, I swear, it was like this when I got here.

module ActiveRecord
  class Base

    def concise_inspect
      "#{self.class}<#{self.id || 'new'}>"
    end

    def self.base_model
      base_class.to_s.underscore
    end

    def base_model
      self.class.base_model
    end
    
    # TODO acts_as_paranoid or similar.
    def deleted?
      false
    end
  end
end
