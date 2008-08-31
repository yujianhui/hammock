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

    def self.visible_to record
      select &read_scope_for(record)
    end
    def visible_to? record
      self.class.read_scope_for(record).call(self)
    end

    def self.editable_by record
      select &write_scope_for(record)
    end
    def editable_by? record
      self.class.write_scope_for(record).call(self)
    end
    
    def self.indexable_by record
      select &index_scope_for(record)
    end
    def indexable_by? record
      self.class.index_scope_for(record).call(self)
    end
    
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
