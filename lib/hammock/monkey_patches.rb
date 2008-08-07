# TODO Oh dear lord these probably shouldn't be here. But that's OK for now.

class Object

  def symbolize
    self.to_s.underscore.to_sym
  end

end

module ActiveRecord
  class Base

    def self.base_model
      to_s.downcase
    end

    def base_model
      self.class.base_model
    end
    
  end
end
